pub fn LinkedQueue(comptime T: type) type {
    return struct {
        const Self = @This();

        pub const OsObject = struct {
            _data: T,
            _to_tail: ?*OsObject = null,
            _to_head: ?*OsObject = null,
            name: []const u8,
        };

        head: ?*OsObject = null,
        tail: ?*OsObject = null,
        elements: u32 = 0,

        ///Add a node to the end of the queue
        pub fn append(self: *Self, node: *OsObject) void {
            if (self.tail) |tail| {
                node._to_head = tail;
                tail._to_tail = node;
                node._to_tail = null;
            } else {
                self.head = node;
                self.tail = node;
            }

            self.tail = node;
            self.elements += 1;
        }

        ///Pop the head node from the queue
        pub fn pop(self: *Self) ?*OsObject {
            const rtn = self.head orelse return null;
            self.head = rtn._to_tail;
            rtn._to_tail = null;
            self.elements -= 1;
            if (self.head) |new_head| {
                new_head._to_head = null;
            } else {
                self.tail = null;
            }
            return rtn;
        }

        ///Returns true if the specified node is contained in the queue
        pub fn contains(self: *Self, node: *OsObject) bool {
            var rtn = false;
            if (self.head) |head| {
                var current_node: *OsObject = head;
                while (true) {
                    if (current_node == node) {
                        rtn = true;
                        break;
                    }
                    if (current_node._to_tail) |next| {
                        current_node = next;
                    } else {
                        break;
                    }
                }
            }

            return rtn;
        }

        ///Removes the specified node from the queue.  Returns false if the node is not contained in the queue.
        pub fn remove(self: *Self, node: *OsObject) bool {
            var rtn = false;

            if (self.contains(node)) {
                if (self.head == self.tail) { //list of 1
                    self.head = null;
                    self.tail = null;
                } else if (self.head == node) {
                    if (node._to_tail) |towardTail| {
                        self.head = towardTail;
                        towardTail._to_head = null;
                    }
                } else if (self.tail == node) {
                    if (node._to_head) |towardHead| {
                        self.tail = towardHead;
                        towardHead._to_tail = null;
                    }
                } else {
                    if (node._to_head) |towardHead| {
                        towardHead._to_tail = node._to_tail;
                    }
                    if (node._to_tail) |towardTail| {
                        towardTail._to_head = node._to_head;
                    }
                }

                node._to_head = null;
                node._to_tail = null;

                self.elements -= 1;
                rtn = true;
            }

            return rtn;
        }

        ///Move the head node control block to the tail position
        pub fn headToTail(self: *Self) void {
            if (self.head != self.tail) {
                if (self.head != null and self.tail != null) {
                    const temp = self.head;
                    self.head.?._to_tail.?._to_head = null;
                    self.head = self.head.?._to_tail;

                    temp.?._to_tail = null;
                    self.tail.?._to_tail = temp;
                    temp.?._to_head = self.tail;
                    self.tail = temp;
                }
            }
        }
    };
}
