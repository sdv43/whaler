namespace Utils {
    string ucfirst (string str) {
        return str.up (1) + str.substring (1);
    }

    string format_container_name (string name) {
        var value = name;

        if (value[0] == '/') {
            value = value.splice (0, 1);
        }

        return ucfirst (value);
    }
}
