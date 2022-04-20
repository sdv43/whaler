using Utils;
using Utils.Constants;

namespace Docker {
    errordomain FrameReaderError {
        ERROR
    }

    class FrameReader : Object {
        public Frame? current_frame;
        public DataInputStream data;
        public MemoryInputStream memory;
        public Container container;
        public bool is_reading;
        public string since;
        public int prev_unparsed_data_size;
        public Cancellable reading_cancel;

        public signal void new_line (string line);

        public FrameReader (Container container) {
            this.since = "0";
            this.is_reading = false;
            this.current_frame = null;
            this.prev_unparsed_data_size = 0;
            this.container = container;
            this.reading_cancel = new Cancellable ();
            this.memory = new MemoryInputStream ();
            this.data = new DataInputStream (this.memory);
        }

        public static size_t read_body_data (void* buf, size_t size, size_t nmemb, void* data) {
            unowned var reader = (FrameReader)data;

            return reader.add_memory_stream_data (buf, size * nmemb);
        }

        public async void read () throws FrameReaderError {
            try{
                if (this.is_reading) {
                    return;
                }

                this.is_reading = true;
                yield this.curl_request ();
                this.is_reading = false;
            } catch (HttpClientError error) {
                throw new FrameReaderError.ERROR (@"Http request error: $(error.message)");
            }
        }

        public size_t add_memory_stream_data (void* buf, size_t size) {
            var buffer = new uint8[size];

            Posix.memcpy ((void*)buffer, buf, size);
            this.memory.add_data (buffer);
            this.parse_frame ((int)size);

            return size;
        }

        public void parse_frame (int size) {
            if (!this.is_reading) {
                return;
            }

            // For the correct operation of the algorithm, at least 8 bytes of data are needed.
            var data_size = this.prev_unparsed_data_size + size;

            // We do not read data until there are 10 bytes
            if (data_size < 10) {
                this.prev_unparsed_data_size = data_size;

                return;
            } else {
                this.prev_unparsed_data_size = 0;
            }

            try {
                while (true) {
                    var bytes_read = 0;

                    // Creating a new frame
                    if (this.current_frame == null) {
                        this.current_frame = new Frame (this.data);

                        bytes_read += this.current_frame.read_type ();
                        bytes_read += this.current_frame.read_size ();

                        //  debug ("create a new frame t:%d, s:%d", this.current_frame.type, this.current_frame.size);
                    }

                    // reading frame body
                    bytes_read += this.current_frame.read_body ();

                    //  debug ("bytes read: %d", bytes_read);

                    if (this.current_frame.is_finish_reading ()) {
                        // all frame data has been read
                        this.new_line ((string)this.current_frame.data.data);
                        this.since = (new DateTime.now_local ()).to_unix ().to_string ();
                        this.current_frame = null;

                        if (bytes_read == data_size) {
                            // no data in buffer
                            break;
                        } else {
                            // there is still data in the buffer
                            data_size -= bytes_read;
                            continue;
                        }
                    } else {
                        if (bytes_read == data_size) {
                            // frame has not been read and no data left
                            break;
                        } else {
                            // error: frame has not been read but data is available
                            warning ("Frame has not been read but data is available");
                        }
                    }
                }
            } catch (IOError error) {
                warning (@"Frame parsing error: $(error.message)");
            }
        }

        private async void curl_request () throws HttpClientError {
            var curl = new Curl.EasyHandle ();

            Curl.Code r;

            r = curl.setopt (Curl.Option.VERBOSE, false);
            assert_true (r == Curl.Code.OK);
            r = curl.setopt (Curl.Option.URL, @"http://localhost/v$(DOCKER_ENIGINE_API_VERSION)/containers/$(this.container.id)/logs?stdout=true&stderr=true&follow=true&since=$(this.since)");
            assert_true (r == Curl.Code.OK);
            r = curl.setopt (Curl.Option.UNIX_SOCKET_PATH, DOCKER_ENGINE_SOCKET_PATH);
            assert_true (r == Curl.Code.OK);
            r = curl.setopt (Curl.Option.CUSTOMREQUEST, "GET");
            assert_true (r == Curl.Code.OK);
            r = curl.setopt (Curl.Option.WRITEDATA, (void*)this);
            assert_true (r == Curl.Code.OK);
            r = curl.setopt (Curl.Option.WRITEFUNCTION, FrameReader.read_body_data);
            assert_true (r == Curl.Code.OK);

            r = yield this.curl_perform (curl);

            if (r != Curl.Code.OK) {
                throw new HttpClientError.ERROR (Curl.Global.strerror (r));
            }

            var http_code = 0;

            curl.getinfo (Curl.Info.RESPONSE_CODE, &http_code);

            //  debug ("curl request http code: %d", http_code);
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

            task.set_return_on_cancel (true);
            task.set_task_data (curl, null);
            task.run_in_thread ((task, http_client, curl, cancellable) => {
                unowned var cl_curl = (Curl.EasyHandle)curl;

                var cl_r = cl_curl.perform ();
                task.return_int (cl_r);
            });

            yield;

            if (err_msg != null) {
                throw new HttpClientError.ERROR (@"Curl perform error: $err_msg");
            }

            return r;
        }
    }

    class Frame : Object {
        public int type;
        public int size;
        public Array<uint8> data;
        public DataInputStream stream;

        public Frame (DataInputStream stream) {
            this.type = -1;
            this.size = 0;
            this.data = new Array<uint8>();
            this.stream = stream;
        }

        public int read_type () throws IOError {
            // stream type https://docs.docker.com/engine/api/v1.41/#operation/ContainerAttach
            this.stream.byte_order = DataStreamByteOrder.LITTLE_ENDIAN;
            this.type = (int)this.stream.read_uint32 ();
            this.stream.byte_order = DataStreamByteOrder.BIG_ENDIAN;

            return 4;
        }

        public int read_size () throws IOError {
            this.size = (int)this.stream.read_uint32 ();

            return 4;
        }

        public int read_body () throws IOError {
            uint8[] buff = new uint8[this.size - this.data.length];

            var bytes_read_total = 0;
            var bytes_read = 0;

            while ((bytes_read = (int)this.stream.read (buff)) != 0) {
                this.data.append_vals (buff, bytes_read);
                bytes_read_total += bytes_read;

                if (this.data.length == this.size) {
                    break;
                }
            }

            return bytes_read_total;
        }

        public bool is_finish_reading () {
            return this.size == this.data.length;
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
                    try{
                        reader.read.end (res);
                    } catch (FrameReaderError error) {
                        warning (@"Log reading error: $(error.message)");
                    }
                });
            }
        }

        public void watching_stop () {
            foreach (var container in this.containers) {
                this.readers[container].reading_cancel.cancel ();
            }
        }

        private FrameReader create_reader (DockerContainer container) {
            assert_true (container.api_container != null);

            var reader = new FrameReader (container.api_container);
            var label = is_label_visible ? @"$(container.name): " : "";

            reader.new_line.connect ((line) => {
                this.buffer_append (label, line, line.length);
            });

            return reader;
        }

        private void buffer_append (string label, string str, int length) {
            Idle.add (() => {
                text_buffer.insert_at_cursor (label, label.length);
                text_buffer.insert_at_cursor (str, length);

                return false;
            }, Priority.DEFAULT_IDLE);
        }
    }
}
