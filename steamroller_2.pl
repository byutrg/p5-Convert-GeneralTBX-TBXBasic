use warnings;
use strict;

#core XML module
use XML::Twig;

#grades similarity of two strings
#used to make guesses (Term_Entry->termEntry)
use String::Similarity;

#configures lower bound of guess validity
#lower tolerance makes bolder guesses, more mistakes
my $tolerance = 0.9;

#version 2.01 is the first development version.
#it is just a test that reads the file and produces
#a test log file using the new and improved logging technique.
my $version = 2.01;

#initialize file;
my $file;

my $test_counter=0;

#open termEntry and log files
open (my $tft,'>','temp_file_text.txt');
open (my $log,'>','log_steamroller.txt');

my %aux_log;

sub log_init {
	my ($t,$section) = @_;
	
	#uses the Elt hash ref as the key
	$aux_log{$section} = {
		'name' 		=> $section->name(),
		'n_fate'	=> 0,
		'line' 		=> $t->current_line(),
		'parent'	=> $section->level()>0 ? $section->parent()->name() : 0,
		'p_fate'	=> 0,
		'text'		=> '', #has to be retrieved later
		't_fate'	=> 0,
		'atts' 		=> {}, #populated in while statement
	};
	
	while (my ($att,$val) = each $section->atts()) 
	#iterates over all atts of the object
	{
		#first value is the original value, second is its 'fate', as above
		$aux_log{$section}{'atts'}{$att} = [$val,0];
	}
	
	return 1;
	
}

sub test_all {
	my ($t,$section) = @_;
	
	$aux_log{$section}{'text'}=$section->children_text('#PCDATA');
	$aux_log{$section}{'text'} =~ s/\s+/ /g;
	print $section->name(), ' ',$t->current_line()," $test_counter","\n"x1;
	
	$test_counter++;
	
	return 1;
}

$file = $ARGV[0];

die "Provide a file!" unless ($file && $file =~ m/\.(tbx|xml|tbxm)\Z/ && -e $file);

my $twig = XML::Twig->new(
	
pretty_print 		=> 'indented',

output_encoding 	=> 'utf-8',

start_tag_handlers 	=> {
	
	_all_ 				=> \&log_init,
	
},

twig_handlers 		=> {
	
	output_html_doctype =>1,
	
	_default_ 			=> \&test_all,
	
}
	
);

$twig->parsefile($file);

#print logfile sorted by linenumber of original
foreach my $section (sort {$aux_log{$a}{'line'} <=> $aux_log{$b}{'line'}} keys %aux_log) 

{
	
	printf "%s of line %d is child of %s.",
	$aux_log{$section}->{'name'},
	$aux_log{$section}->{'line'},
	$aux_log{$section}->{'parent'} ? $aux_log{$section}->{'parent'} : 'root';
	
	while (my($att,$contents) = each $aux_log{$section}{'atts'}) 
	
	{
		printf "\n%s has attribute %s:%s.",
		$aux_log{$section}->{'name'},
		$att, $contents->[0],
		;
	}
	
	if ($aux_log{$section}->{'text'}) 
	{
		printf "\n%s has text '%s'.",
		$aux_log{$section}->{'name'},
		$aux_log{$section}->{'text'},
		;
	} 
	
	print "\n\n";
}

$twig->purge();

