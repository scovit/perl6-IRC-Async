use v6;
use IRC::Parser; # parse-irc

# This should be a supplier

unit class IRC::Async:ver<0.9>;

has Bool:D $.debug                          = False;
has Str:D  $.host                           = 'localhost';
has Str    $.password;
has Int:D  $.port where 0 <= $_ <= 65535    = 6667;
has Str:D  $.nick                           = 'EvilBOT';
has Str:D  $.username                       = 'EvilBOT';
has Str:D  $.userhost                       = 'localhost';
has Str:D  $.userreal                       = 'Evil annoying BOT';
has Str:D  @.channels                       = ['#perl6bot'];

has IO::Socket::Async $.sock;
has Supplier          $.supplier;

method connect returns Promise {
    start {
	await IO::Socket::Async.connect( $!host, $!port ).then(
	    {
		$!sock = .result;
		$!supplier = Supplier.new;
		
		$.ssay("PASS $!password\n") if $!password.defined;
		$.ssay("NICK $!nick\n");
		$.ssay("USER $!username $!username $!host :$!userreal\n");
		$.ssay("JOIN {@!channels[]}\n");

		$!sock.Supply(:bin).tap(
		    -> $buf is copy {
			my $str      = try $buf.decode: 'utf8';
			$str or $str = $buf.decode: 'latin-1';
			$!debug and "[server {DateTime.now}] {$str}".put;
			my $events = parse-irc $str;

			for @$events -> $e {
			    $!supplier.emit($e);
			}
		    });
	    });
	self;
    }
}

method Supply returns Supply {
    $!supplier.Supply;
}

method ssay (Str:D $msg) {
    $!debug and $msg.put;
    $!sock.print("$msg\n");
    self;
}

method privmsg (Str $who, Str $what) {
    my $msg = "PRIVMSG $who :$what\n";
    $!debug and $msg.put;
    $!sock.print($msg);
    self;
}
