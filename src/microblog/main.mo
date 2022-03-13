import List "mo:base/List";
import Iter "mo:base/Iter";
import Principal "mo:base/Principal";
import Time "mo:base/Time";

actor {
    public type Message = {
        time: Time.Time;
        message: Text;
    };

    public type Microblog = actor {
        follow: shared(Principal) -> async ();
        follows: shared query () -> async [Principal];
        post: shared (Text) -> async ();
        posts: shared query (Time.Time) -> async [Message];
        timeline: shared (Time.Time) -> async [Message];
    };

    stable var followed: List.List<Principal> = List.nil();

    public shared func follow(id: Principal) : async () {
        followed := List.push(id, followed);
    };

    public shared query func follows() : async [Principal] {
        List.toArray(followed)
    };

    stable var messages: List.List<Message> = List.nil();

    public shared (msg) func post(text: Text) : async () {
        let message = {
            message = text;
            time = Time.now();
        };
        messages := List.push(message, messages);
    };

    // 仅返回指定时间之后的内容
    public shared query func posts(since: Time.Time) : async [Message] {
        var latest: List.List<Message> = List.nil();
        var idx = 0;
        while (idx < List.size(messages)) {
            let tmp: ?Message = List.get<Message>(messages, idx);
            switch (tmp) {
                case null {};
                case (?m) {
                    if (m.time > since) {
                        latest := List.push(m, latest);
                    };
                };
            };
            idx += 1;
        };
        List.toArray(latest)
    };

    // 仅返回指定时间之后的内容
    public shared func timeline(since: Time.Time) : async [Message] {
        var all: List.List<Message> = List.nil();
        for (id in Iter.fromList(followed)) {
            let canister: Microblog = actor(Principal.toText(id));
            let msgs = await canister.posts(since);
            for (msg in Iter.fromArray(msgs)) {
                all := List.push(msg, all);
            };
        };

        List.toArray(all)
    };
};
