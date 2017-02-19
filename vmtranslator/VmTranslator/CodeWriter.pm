# In Perl there is no special 'class' definition.  A namespace is a class.
package VmTranslater::CodeWriter;

use strict;
use warnings;
 
our $VERSION = "1.00";

=head1 NAME
 
VmTranslater::CodeWriter - Translates VM commands into Hack assembly code
 
=head1 SYNOPSIS
 
    use Hello::World;
    my $hello = Hello::World->new();
    $hello->print;
 
=head1 DESCRIPTION
 
Translates VM commands into Hack assembly code
 
=head2 Methods
 
=head3 new
 
    my $hello = Hello::World->new();
    my $hello = Hello::World->new( target => $target );
 
Instantiates an object which holds a greeting message.  If a C<$target> is
given it is passed to C<< $hello->target >>.
 
=cut
 
 my $fh;
 
# The constructor of an object is called new() by convention.  Any
# method may construct an object and you can have as many as you like.
 sub new {
 my($class, %args) = @_;
 
 my $self = bless({}, $class);
 
 open $fh, '>', $args{filename} or die "Could not open '$args{filename}' $!\n";
 
 return $self;
}
 
 
=head3 setFileName
 
	$codeWriter->setFileName($fileName);

Informs the code writer that the translation of a new VM file is started.
	
=cut
 
sub setFileName {
	my $self = shift;
	my $fileName = shift;
	# TODO Set up parser with fileName here
	...;
}
 
 
=head3 writeArithmetic
 
    $codeWriter->writeArithmetic($command);
 
Writes the assembly code that is the translation of the given arithmetic command.
 
=cut
 
sub writeArithmetic {
	my $self = shift;
	my $command = shift;
	...;
}
 
 
=head3 writePushPop
 
    $codeWriter->writePushPop($command, $segment, $index);
 
Writes the assembly code that is the translation of the given command, where $command is either C_PUSH or C_POP.
 
=cut
 
sub writePushPop {
	my $self = shift;
	my ($command, $segment, $index) = @_;
	...;
}

=head3 close
 
    $codeWriter->close;
 
Closes the output file.
 
=cut


sub close
{
	...;
}

sub DESTROY {
	my $self = shift;
	# TODO: Needed?
	
	#close $self->$fh;
}

 
=head1 AUTHOR
 
Dave
 
=cut
 
1;