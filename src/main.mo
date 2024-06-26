import Principal "mo:base/Principal";
import Time "mo:base/Time";
import Timer "mo:base/Timer";
import Text "mo:base/Text";
shared ({ caller = creator }) actor class UserCanister(
    yourName : Text
) = this {

    public type Mood = Text;
    public type Name = Text;

    let name : Name = yourName;
    let owner : Principal = creator;
    let nanosecondsPerDay = 24 * 60 * 60 * 1_000_000_000;

    let board = actor ("q3gy3-sqaaa-aaaas-aaajq-cai") : actor {
        reboot_writeDailyCheck : (name : Name, mood : Mood) -> async ();
    };

    stable var alive : Bool = true;
    stable var latestPing : Time.Time = Time.now();

    func _kill() : async () {
        let now = Time.now();
        if (now - latestPing > nanosecondsPerDay) {
            alive := false;
        };
    };

    // Timer to reset the alive status every 24 hours
    let _daily = Timer.recurringTimer<system>(#nanoseconds(nanosecondsPerDay), _kill);

    // The idea here is to have a function to call every 24 hours to indicate that you are alive
    public shared ({ caller }) func reboot_dailyCheck(
        mood : Mood
    ) : async () {
        assert (caller == owner);
        alive := true;
        latestPing := Time.now();

        // Write the daily check to the board
        try {
            await board.reboot_writeDailyCheck(name, mood);
        } catch (e) {
            throw e;
        };
    };

    public query func reboot_isAlive() : async Bool {
        return alive;
    };

};