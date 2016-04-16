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

		$!sock.Supply(:bin).act(
		    -> $buf is copy {
			my $str      = try $buf.decode: 'utf8';
			$str or $str = $buf.decode: 'latin-1';
			$!debug and "[server {DateTime.now}] {$str}".put;
			my $events = parse-irc $str;

			for @$events -> $e {
			    $!supplier.emit($e);
			}
		    });

                my @connect-messages;
                push @connect-messages, $.print("PASS $!password\n") if $!password.defined;
                push @connect-messages, $.print("NICK $!nick\n");
                push @connect-messages, $.print("USER $!username $!username $!host :$!userreal\n");
                push @connect-messages, $.print("JOIN {@!channels[]}\n");
                await Promise.allof(@connect-messages);

	    });
	self;
    }
}

method Supply returns Supply {
    $!supplier.Supply;
}

method print (Str:D $msg) returns Promise {
    $!debug and $msg.put;
    $!sock.print("$msg\n");
}

method write (Blob:D $msg) returns Promise {
    $!debug and $msg.put;
    $!sock.write("$msg\n");
}

method close {
    self.print("\\quit");
    $!sock.close;
    $!supplier.done;
}

method privmsg (Str $who, Str $what) returns Promise {
    my $msg = "PRIVMSG $who :$what\n";
    self.print($msg);
}
