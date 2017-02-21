# In Perl there is no special 'class' definition.  A namespace is a class.
package VmTranslator::Parser;

use strict;
use warnings;
 
our $VERSION = "1.00";

=head1 NAME
 
VmTranslater::Parser - parser module of vm for nad2tertris
 
=head1 SYNOPSIS
 
    use Hello::World;
    my $hello = Hello::World->new();
    $hello->print;
 
=head1 DESCRIPTION
 
Handles parsing of a singel .vm file and encapsulates access to the input code.
It reads VM commands, parses them, and provides convenient access to their components.
In addition it removes all whitespace and comments.
 
=head2 Methods
 
=head3 new
 
    my $hello = Hello::World->new();
    my $hello = Hello::World->new( target => $target );
 
Instantiates an object which holds a greeting message.  If a C<$target> is
given it is passed to C<< $hello->target >>.
 
=cut
 
# The constructor of an object is called new() by convention.  Any
# method may construct an object and you can have as many as you like.
 sub new {
 my($class, %args) = @_;
 
 my $self = bless({}, $class);
 
 open my $fh, '<', $args{filename} or die "Could not open '$args{filename}' $!\n";
 
 $self->{filehandle} = $fh;
 
 return $self;
}
 
 
=head3 hasMoreCommands
 
	my $thereAreMore = $parser->hasMoreCommands;

 Are there more commands in the input?
	
=cut
 
sub hasMoreCommands {
	my $self = shift;
	return !eof($self->{filehandle}); 
}
 
 
=head3 advance
 
    $parser->advance;
 
Reads the next command from the input and makes it the current command. Should only be called if hasMoreCommands is true. Initially there is no current command.
 
=cut
 
sub advance {
	my $self = shift;
	my $currentLine;
	$self->{command} = "no";
	my $fh = $self->{filehandle};
	while($self->{command} eq "no" and $currentLine = <$fh>) {
		chomp $currentLine;
		$currentLine =~ s/^\s+//; # left trim spaces
		$currentLine =~ s/\/\/.*$//; # strip right comments
		$currentLine =~ s/\s+$//; # strip right spaces
		$currentLine =~ s/\s+/ /; # replace multiple white space with single white space
		
		$self->{command} = $currentLine;
	}
}
 
 
=head3 commandType
 
    $parser->commandType;
 
Returns the type of the current VM command. C_ARITHMETIC is returned for all the aritimetic commands.
Return values are 
C_ARITMETIC, C_PUSH, C_POP, C_LABEL, C_GOTO, C_IF, C_FUNCTION, C_RETURN, C_CALL
 
=cut
 
sub commandType {
	my $self = shift;
	# TODO Consider hash table
	return "C_ARITHMETIC" if($self->{command} =~ /add|sub|neg|eq|gt|lt|and|or|not/i);
	return "C_PUSH" if($self->{command} =~ /push/i);
	return "C_POP" if($self->{command} =~ /pop/i);
	
	# TODO: Not to spec...!
	return "C_UNKNOWN";
}

=head3 arg1
 
    $parser->arg1;
 
Returns the first argument of the current command. In the case of C_ARITMETIC, the command itself (add, sub, etc) is returned. Should not be called if the current command is C_RETURN.
 
=cut


sub arg1 {
	my $self = shift;
	return $self->{command} if($self->commandType eq "C_ARITHMETIC");
	my ($thecommand, $thearg1, @other) = split(/ /, $self->{command});
	return $thearg1;
}

=head3 arg2
 
    $parser->arg2;
 
Returns the second argument of the current command. Should be called only if the current command is C_PUSH, C_POP, C_FUNCTION, or C_CALL.
 
=cut


sub arg2 {
	my $self = shift;
	my ($thecommand, $thearg1, $thearg2) = split(/ /, $self->{command});
	return $thearg2;
}



sub DESTROY {
	my $self = shift;
	
	close $self->{filehandle};
}

 
=head1 AUTHOR
 
Dave
 
=cut
 
1;