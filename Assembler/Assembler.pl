# Assembler.pl

use strict;
use warnings;
use feature qw(say);


my %opcodes = (
	"0" => "0101010",
	"1" => "0111111",
	"-1" => "0111010",
	"D" => "0001100",
	"A" => "0110000",
	"!D" => "0001101",
	"!A" => "0110001",
	"-D" => "0001111",
	"-A" => "0110011",
	"D+1" => "0011111",
	"A+1" => "0110111",
	"D-1" => "0001110",
	"A-1" => "0110010",
	"D+A" => "0000010",
	"D-A" => "0010011",
	"A-D" => "0000111",
	"D&A" => "0000000",
	"D|A" => "0010101",
	"M" => "1110000",
	"!M" => "1110001",
	"-M" => "1110011",
	"M+1" => "1110111",
	"M-1" => "1110010",
	"D+M" => "1000010",
	"D-M" => "1010011",
	"M-D" => "1000111",
	"D&M" => "1000000",
	"D|M" => "1010101"
);

my %destcodes = (
	"null" => "000",
	"M" => "001",
	"D" => "010",
	"MD" => "011",
	"A" => "100",
	"AM" => "101",
	"AD" => "110",
	"AMD" => "111"
);

my %jumpcodes = (
	"null" => "000",
	"JGT" => "001",
	"JEQ" => "010",
	"JGE" => "011",
	"JLT" => "100",
	"JNE" => "101",
	"JLE" => "110",
	"JMP" => "111"
);

my %symbols = (
	"SP" 		=> "000000000000000",
	"LCL" 		=> "000000000000001",
	"ARG" 		=> "000000000000010",
	"THIS" 		=> "000000000000011",
	"THAT" 		=> "000000000000100",
	"R0" 		=> "000000000000000",
	"R1" 		=> "000000000000001",
	"R2" 		=> "000000000000010",
	"R3" 		=> "000000000000011",
	"R4" 		=> "000000000000100",
	"R5" 		=> "000000000000101",
	"R6" 		=> "000000000000110",
	"R7" 		=> "000000000000111",
	"R8" 		=> "000000000001000",
	"R9" 		=> "000000000001001",
	"R10" 		=> "000000000001010",
	"R11" 		=> "000000000001011",
	"R12"		=> "000000000001100",
	"R13" 		=> "000000000001101",
	"R14" 		=> "000000000001110",
	"R15" 		=> "000000000001111",
	"SCREEN" 	=> "100000000000000",
	"KBD" 		=> "110000000000000"
);


#
# Returns the type of the current command:
# A_COMMAND
# for @Xxx where Xxx is either a symbol or a decimal number
# 
# C_COMMAND
# for dest=comp;jump
# 
# L_COMMAND
# (actually, pseudo-command) for (Xxx) where Xxx is a symbol.
sub commandType {
	# return A_COMMAND, C_COMMAND, L_COMMAND
	
	my $command = shift;
	
	return "C_COMMAND" if($command =~ /=|;/);
	
	return "A_COMMAND" if($command =~ /@/);
	
	return "L_COMMAND" if($command =~ /\(*\)/);
	
	return "No";
}


#
# Returns the symbol or decimal Xxx
# of the current command @Xxx or (Xxx)
# . Should be called only when commandType()
# is A_COMMAND or L_COMMAND
sub symbol {
	my $symbol = symbol_name(shift);
	return $symbols{$symbol} if (exists $symbols{$symbol}); # return if symbol has address
	return dec2bin($symbol);
}

sub symbol_name {
	my $command = shift;
	$command =~ tr/@\(\)//d; # remove @ and ()
	return $command;
}


#
# Returns the dest mnemonic in
# the current C-command (8 possibilities). 
# Should be called only when commandType()
# is C_COMMAND.
sub dest {
	my $command = shift;
	if($command =~ /=/) # "dest=comp" format
	{
		my ($dest, @other) = split(/=/, $command);
		return $destcodes{$dest};
	}
	return $destcodes{"null"};
	# TODO defensive
}


#
# Returns the comp mnemonic in
# the current C-command (28 possibilities). 
# Should be called only when commandType()
# is C_COMMAND.
sub comp {
	my $command = shift;
	if($command =~ /=/) # "dest=comp"
	{
		my ($other, $comp) = split(/=/, $command);
		return $opcodes{$comp};
	}
	if($command =~ /;/) # "comp;jump"
	{
		my ($comp, $other) = split(/;/, $command);
		return $opcodes{$comp};
	}
	return "";
}


#
# Returns the jump mnemonic in
# the current C-command (8 possibilities). 
# Should be called only when commandType()
# is C_COMMAND.
sub jump {
	my $command = shift;
	if($command =~ /;/) # "comp;jump"
	{
		my ($other, $jump) = split(/;/, $command); # assuming there's no D=0;JMP types...
		return $jumpcodes{$jump};
	}
	return $jumpcodes{"null"};
}


sub dec2bin {
    my $str = unpack("B32", pack("N", shift));
    #$str =~ s/^0+(?=\d)//;   # otherwise you'll get leading zeros
    return substr($str, -15);
}

sub clean_line {
	my $line = shift;
	chomp $line;
	$line =~ s/^\s+//; # left trim spaces
	$line =~ s/\/\/.*$//; # strip right comments
	$line =~ s/\s+$//; # strip right spaces
	return $line;
}

##
## initialise
my $DEBUG_COMMAND_DETECTION = 0;
my $DEBUG_OUTPUT_SxS = 0;
my $DEBUG_LIST_SYMBOLS = 0;
my $ASSEMBLE = 1;

my $lineNumber = 0;
my $variableCounter = 0;

my $file = '.\Pong.asm'; #shift

#
# Pass 1
open my $fh, '<', $file or die "Could not open '$file' $!\n";
while(my $line = <$fh>)
{
	# First pass L_COMMAND only
	# Second pass C_ and A_COMMANDs only
	
	$line = clean_line($line);

	my $commandType = commandType($line);
	
	# Debug lines
	say "$commandType\t:$line" if($DEBUG_COMMAND_DETECTION);
	
	if($commandType eq "C_COMMAND" || $commandType eq "A_COMMAND")
	{
		$lineNumber++;
	}
	elsif($commandType eq "L_COMMAND")
	{
		my $symbol = symbol_name $line;
		if(exists $symbols{$symbol})
		{
			# no need to do owt...
		}
		else
		{
			$symbols{$symbol} = dec2bin($lineNumber);
		}
		say "$symbol:\t$symbols{$symbol}" if($DEBUG_LIST_SYMBOLS);
	}
}
close $fh;

#
# Pass 2
open $fh, '<', $file or die "Could not open '$file' $!\n";
while(my $line = <$fh>)
{
	# First pass L_COMMAND only
	# Second pass C_ and A_COMMANDs only
	
	$line = clean_line($line);

	my $commandType = commandType($line);
	
	# Debug lines
	say "$commandType\t:$line" if($DEBUG_COMMAND_DETECTION);
	
	if($commandType eq "C_COMMAND")
	{
		my $dest = dest $line;
		my $comp = comp $line;
		my $jump = jump $line;
		my $bin = "111$comp$dest$jump";
		say "$line:\t$bin" if($DEBUG_OUTPUT_SxS);
		say $bin if($ASSEMBLE);
	}
	elsif($commandType eq "A_COMMAND")
	{
		my $symbol = "";
		my $symbol_name = symbol_name($line);
		if($symbol_name =~ /^[0-9]+$/)
		{
			# It's a number
			$symbol = dec2bin($symbol_name);
		}
		else
		{
			if(!exists($symbols{$symbol_name}))
			{
				$symbols{$symbol_name} = dec2bin(16 + $variableCounter++);
			}
			$symbol = $symbols{$symbol_name};
		}
		say "$line:\t0$symbol" if($DEBUG_OUTPUT_SxS);
		say "0$symbol" if($ASSEMBLE);
	}
}
close $fh;


