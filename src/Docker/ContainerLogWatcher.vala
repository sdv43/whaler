/*
   This file is part of Whaler.

   Whaler is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License
   as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.
   Whaler is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty
   of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

   You should have received a copy of the GNU General Public License along with Whaler. If not, see <https://www.gnu.org/licenses/>.
 */

using Utils;
using Utils.Constants;

namespace Docker {
    errordomain FrameReaderError {
        ERROR
    }

    class FrameReader : Object {
        // Multiplexed stream frame header: stream type (1 byte), 3 zero bytes, payload size (uint32 big endian)
        // https://docs.docker.com/engine/api/v1.44/#tag/Container/operation/ContainerAttach
        private const uint FRAME_HEADER_SIZE = 8;

        public Container container;
        public bool is_reading;
        public string since;
        public Cancellable reading_cancel;

        // Received data that does not form a complete frame yet
        private ByteArray pending;
        // TTY containers send raw output instead of multiplexed frames
        private bool is_raw_stream;

        public signal void new_line (string line);

        public FrameReader (Container container) {
            this.since = "0";
            this.is_reading = false;
            this.is_raw_stream = false;
            this.container = container;
            this.reading_cancel = new Cancellable ();
            this.pending = new ByteArray ();
        }

        public static size_t read_header_data (void* buf, size_t size, size_t nmemb, void* data) {
            unowned var reader = (FrameReader)data;
            var header = ((string)buf).substring (0, (long)(size * nmemb)).down ();

            if (header.has_prefix ("content-type:") && header.contains ("application/vnd.docker.raw-stream")) {
                reader.is_raw_stream = true;
            }

            return size * nmemb;
        }

        public static size_t read_body_data (void* buf, size_t size, size_t nmemb, void* data) {
            unowned var reader = (FrameReader)data;

            // returning less than received aborts the transfer
            if (reader.reading_cancel.is_cancelled ()) {
                return 0;
            }

            return reader.add_stream_data (buf, size * nmemb);
        }

        public static int progress_callback (void* clientp, double dltotal, double dlnow, double ultotal, double ulnow) {
            unowned var reader = (FrameReader)clientp;

            return reader.reading_cancel.is_cancelled () ? 1 : 0;
        }

        public async void read () throws FrameReaderError {
            if (this.is_reading || this.reading_cancel.is_cancelled ()) {
                return;
            }

            try {
                this.is_reading = true;
                yield this.curl_request ();
            } catch (HttpClientError error) {
                if (!this.reading_cancel.is_cancelled ()) {
                    throw new FrameReaderError.ERROR (@"Http request error: $(error.message)");
                }
            } finally {
                this.is_reading = false;
            }
        }

        public size_t add_stream_data (void* buf, size_t size) {
            unowned uint8[] chunk = (uint8[])buf;
            chunk.length = (int)size;

            this.pending.append (chunk);

            if (this.is_raw_stream) {
                this.parse_raw ();
            } else {
                this.parse_frames ();
            }

            return size;
        }

        private void parse_frames () {
            unowned uint8[] data = this.pending.data;
            uint offset = 0;

            while (data.length - offset >= FRAME_HEADER_SIZE) {
                var size = (uint)data[offset + 4] << 24 | (uint)data[offset + 5] << 16 | (uint)data[offset + 6] << 8 | (uint)data[offset + 7];

                if (data.length - offset - FRAME_HEADER_SIZE < size) {
                    // wait for the rest of the frame
                    break;
                }

                var line = new uint8[size + 1];
                Memory.copy (line, &data[offset + FRAME_HEADER_SIZE], size);
                line[size] = 0;

                this.new_line ((string)line);
                offset += FRAME_HEADER_SIZE + size;
            }

            if (offset > 0) {
                this.pending.remove_range (0, offset);
                this.update_since ();
            }
        }

        private void parse_raw () {
            uint8[] nul = {0};
            this.pending.append (nul);

            this.new_line ((string)this.pending.data);
            this.pending.set_size (0);
            this.update_since ();
        }

        private void update_since () {
            // sub-second precision, otherwise lines of the last second are received again on resume
            var now = new DateTime.now_utc ();
            this.since = "%lld.%06d".printf (now.to_unix (), now.get_microsecond ());
        }

        private async void curl_request () throws HttpClientError {
            var settings = new Settings (APP_ID);
            var curl = new Curl.EasyHandle ();
            var tail = this.since == "0" ? "1000" : "all";

            // Podman does not multiplex the log stream
            this.is_raw_stream = settings.get_string ("docker-api-socket-path").contains ("podman.sock");
            this.pending.set_size (0);

            Curl.Code r;

            r = curl.setopt (Curl.Option.VERBOSE, (long)0);
            assert_true (r == Curl.Code.OK);
            r = curl.setopt (Curl.Option.NOPROGRESS, (long)0);
            assert_true (r == Curl.Code.OK);
            r = curl.setopt (Curl.Option.PROGRESSDATA, (void*)this);
            assert_true (r == Curl.Code.OK);
            r = curl.setopt (Curl.Option.PROGRESSFUNCTION, FrameReader.progress_callback);
            assert_true (r == Curl.Code.OK);
            r = curl.setopt (Curl.Option.URL, @"http://localhost/v$(DOCKER_ENIGINE_API_VERSION)/containers/$(this.container.id)/logs?stdout=true&stderr=true&follow=true&since=$(this.since)&tail=$(tail)");
            assert_true (r == Curl.Code.OK);
            r = curl.setopt (Curl.Option.UNIX_SOCKET_PATH, settings.get_string ("docker-api-socket-path"));
            assert_true (r == Curl.Code.OK);
            r = curl.setopt (Curl.Option.CUSTOMREQUEST, "GET");
            assert_true (r == Curl.Code.OK);
            r = curl.setopt (Curl.Option.HEADERDATA, (void*)this);
            assert_true (r == Curl.Code.OK);
            r = curl.setopt (Curl.Option.HEADERFUNCTION, FrameReader.read_header_data);
            assert_true (r == Curl.Code.OK);
            r = curl.setopt (Curl.Option.WRITEDATA, (void*)this);
            assert_true (r == Curl.Code.OK);
            r = curl.setopt (Curl.Option.WRITEFUNCTION, FrameReader.read_body_data);
            assert_true (r == Curl.Code.OK);

            r = yield this.curl_perform (curl);

            if (this.reading_cancel.is_cancelled ()) {
                return;
            }

            if (r != Curl.Code.OK) {
                throw new HttpClientError.ERROR (Curl.Global.strerror (r));
            }

            long http_code = 0;

            curl.getinfo (Curl.Info.RESPONSE_CODE, &http_code);

            //  debug ("curl request http code: %ld", http_code);
        }

        private async Curl.Code curl_perform (Curl.EasyHandle curl) throws HttpClientError {
            string? err_msg = null;
            var r = Curl.Code.OK;

            var task = new Task (this, this.reading_cancel, (obj, cl_task) => {
                try {
                    r = (Curl.Code)cl_task.propagate_int ();
                } catch (Error error) {
                    err_msg = error.message;
                } finally {
                    this.curl_perform.callback ();
                }
            });

            task.set_task_data (curl, null);
            task.run_in_thread ((task, http_client, curl, cancellable) => {
                unowned var cl_curl = (Curl.EasyHandle)curl;

                var cl_r = cl_curl.perform ();
                task.return_int (cl_r);
            });

            yield;

            if (err_msg != null && !this.reading_cancel.is_cancelled ()) {
                throw new HttpClientError.ERROR (@"Curl perform error: $err_msg");
            }

            return r;
        }
    }

    class ContainerLogWatcher : Object {
        public Gee.ArrayList<DockerContainer> containers {get; construct set;}
        public Gtk.TextBuffer text_buffer {get; construct set;}
        public Gee.HashMap<DockerContainer, FrameReader> readers;
        private bool is_label_visible;

        public ContainerLogWatcher (DockerContainer container, Gtk.TextBuffer buffer) {
            this.is_label_visible = container.type == DockerContainerType.GROUP;
            this.text_buffer = buffer;
            this.containers = new Gee.ArrayList<DockerContainer> (DockerContainer.equal);
            this.readers = new Gee.HashMap<DockerContainer, FrameReader>(
                null,
                DockerContainer.equal,
                (a, b) => {return a.container.id == b.container.id;}
            );

            if (container.type == DockerContainerType.GROUP) {
                this.containers.add_all (container.services);
            } else {
                this.containers.add (container);
            }
        }

        public void watching_start () {
            foreach (var container in this.containers) {
                var reader = this.readers[container];

                if (reader == null) {
                    reader = this.create_reader (container);
                    this.readers[container] = reader;
                }

                reader.read.begin ((_, res) => {
                    try {
                        reader.read.end (res);
                    } catch (FrameReaderError error) {
                        warning (@"Log reading error: $(error.message)");
                    }
                });
            }
        }

        // A stopped watcher cannot be started again, create a new one instead
        public void watching_stop () {
            foreach (var container in this.containers) {
                var reader = this.readers[container];
                if (reader != null) {
                    reader.reading_cancel.cancel ();
                }
            }
        }

        private FrameReader create_reader (DockerContainer container) {
            assert_true (container.api_container != null);

            var reader = new FrameReader (container.api_container);
            var reading_cancel = reader.reading_cancel;
            var label = is_label_visible ? @"$(container.name): " : "";

            reader.new_line.connect ((line) => {
                this.buffer_append (reading_cancel, label, line, line.length);
            });

            return reader;
        }

        private void buffer_append (Cancellable reading_cancel, string label, string str, int length) {
            Idle.add (() => {
                // drop lines that were queued before the watcher was stopped
                if (reading_cancel.is_cancelled ()) {
                    return false;
                }

                // append to the end, the cursor can be moved by clicking in the log
                Gtk.TextIter end;
                text_buffer.get_end_iter (out end);
                text_buffer.insert (ref end, label, label.length);
                text_buffer.insert (ref end, str, length);

                return false;
            }, Priority.DEFAULT_IDLE);
        }
    }
}
