# In Perl there is no special 'class' definition.  A namespace is a class.
package VmTranslator::CodeWriter;

use strict;
use warnings;
use Carp qw(croak carp);
 
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
 
# The constructor of an object is called new() by convention.  Any
# method may construct an object and you can have as many as you like.
 sub new {
	my($class, %args) = @_;

	my $self = bless({}, $class);

	# Open output file and store handle
	open my $fh, '>', $args{filename} or die "Could not open '$args{filename}' $!\n";
	$self->{filehandle} = $fh;

	# Set up instruction strings
	my $instructions = {
		"popintovar1" => "\@SP\nM=M-1\n\@SP\nA=M\nD=M\n\@var1\nM=D\n",
		"popintovar2" => "\@SP\nM=M-1\n\@SP\nA=M\nD=M\n\@var2\nM=D\n",
		"pushresult" => "\@SP\nA=M\nM=D\n\@SP\nM=M+1\n",
		"add" => "\@var1\nD=M\n\@var2\nD=D+M\n",
		"sub" => "\@var1\nD=M\n\@var2\nD=D-M\n",
		"and" => "\@var1\nD=M\n\@var2\nD=D&M\n",
		"or" => "\@var1\nD=M\n\@var2\nD=D|M\n",
		"neg" => "\@var1\nD=-M\n",
		"not" => "\@var1\nD=!M\n",
		"more" => "..."
	};
	$self->{instructions} = $instructions;
	
	# Write initial preamble to file
	# TODO Put these into hash
	print $fh "// Set up stack\n\@256\nD=A\n\@SP\nM=D\n";
	print $fh "// local segment\n\@300\nD=A\n\@LCL\nM=D\n";
	print $fh "// argument segment\n\@400\nD=A\n\@ARG\nM=D\n";
	print $fh "// this segment\n\@3000\nD=A\n\@THIS\nM=D\n";
	print $fh "// that segment\n\@3010\nD=A\n\@THAT\nM=D\n";
	#print $fh "// temp segment\n\@5\nD=A\n\@TEMP\nM=D\n";
	#print $fh "// register segment\n\@13\nD=A\n\@REG\nM=D\n";
	
	# Set initial lablecounter to 0
	$self->{labelcounter} = 0;

 	return $self;
}
 
 
=head3 setFileName
 
	$codeWriter->setFileName($fileName);

Informs the code writer that the translation of a new VM file is started.
	
=cut
 
sub setFileName {
	my $self = shift;
	my $filename = shift;
	# TODO Informs code writer that translation of a new .vm file has started - only one codewriter for all .vms
	my($vmname, @other) = split(/\./, $filename);
	
	$self->{vmname} = $vmname;
}
 
 
=head3 writeArithmetic
 
    $codeWriter->writeArithmetic($command);
 
Writes the assembly code that is the translation of the given arithmetic command.
 
=cut
 
sub writeArithmetic {
	my $self = shift;
	my $command = shift;
	my $fh = $self->{filehandle};
	my $instructions = $self->{instructions};
	
	if($command =~ /add|sub|and|or/) {
		print $fh $instructions->{"popintovar2"};
		print $fh $instructions->{"popintovar1"};
		print $fh $instructions->{$command};
		print $fh $instructions->{"pushresult"};
		return;
	}
	if($command =~ /eq|gt|lt/) {
		my $labelCounter = $self->{labelcounter};
		my $labelStart = "__START$labelCounter";
		my $labelEnd = "__END$labelCounter";
		my $jump = 'J'.(uc($command));
		
		print $fh $instructions->{"popintovar2"};
		print $fh $instructions->{"popintovar1"};
		print $fh $instructions->{"sub"};
		print $fh "\@$labelStart\nD;$jump\n\@0\nD=A\n\@$labelEnd\n0;JMP\n($labelStart)\n\@0\nD=!A\n($labelEnd)\n";
		print $fh $instructions->{"pushresult"};
		
		$self->{labelcounter} = $labelCounter + 1;
		return;
	}
	if($command =~ /neg|not/) {
		print $fh $instructions->{"popintovar1"};
		print $fh $instructions->{$command};
		print $fh $instructions->{"pushresult"};
		return;
	}
	croak "Error in arithmetic: $command is not command.";
}
 
 
=head3 writePushPop
 
    $codeWriter->writePushPop($command, $segment, $index);
 
Writes the assembly code that is the translation of the given command, where $command is either C_PUSH or C_POP.
 
=cut
 
sub writePushPop {
	my $self = shift;
	my ($command, $segment, $index) = @_;
	
	my $fh = $self->{filehandle};
	my $instructions = $self->{instructions};
	
	if($command eq "C_PUSH") {
		if($segment eq "constant") {
			print $fh "\@$index\nD=A\n";
			print $fh $instructions->{"pushresult"};
			return;
		}
		else {
			print $fh "\@$index\nD=A\n";
		
			print $fh "\@LCL\n" if($segment eq "local");
			print $fh "\@ARG\n" if($segment eq "argument");
			print $fh "\@THIS\n" if($segment eq "this");
			print $fh "\@THAT\n" if($segment eq "that");
			print $fh "\@5\n" if($segment eq "temp");
			
			print $fh "A=D+M\n\@mem\nM=A\n"; # location of segment+index in @mem
			
			print $fh "\@mem\nA=M\nD=M\n";
			print $fh $instructions->{"pushresult"};
			
			return;
		}
	}
	
	if($command eq "C_POP") {
		print $fh $instructions->{"popintovar1"};
		# Pop from stack into segment
		print $fh "\@$index\nD=A\n";
		
		print $fh "\@LCL\n" if($segment eq "local");
		print $fh "\@ARG\n" if($segment eq "argument");
		print $fh "\@THIS\n" if($segment eq "this");
		print $fh "\@THAT\n" if($segment eq "that");
		print $fh "\@5\n" if($segment eq "temp");
		#TODO Bounds checking!
		print $fh "// here\n";
		print $fh "A=D+M\n\@mem\nM=A\n\@var1\nD=M\n\@mem\nA=M\nM=D\n";
		return;
	}
	
	croak "Error in pushpop: $command is not command.";
	
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
	my $fh = $self->{filehandle}; 
	#close $fh;
}

 
=head1 AUTHOR
 
Dave
 
=cut
 
1;