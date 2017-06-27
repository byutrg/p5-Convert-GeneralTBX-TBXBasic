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

#version 2.02 converts the log printer into a function
my $version = 2.02;

#initialize file;
my $file;

my $test_counter=0;

#open termEntry and log files
open (my $tft,'>','temp_file_text.txt');
open (my $log,'>','log_steamroller.txt');

my %aux_log;
my %term_log;

sub aux_log_init {
	my ($t,$section) = @_;
	#passes reference for %aux_log to &log_init
	log_init($t,$section,\%aux_log);
}

sub term_log_init {
	my ($t,$section) = @_;
	#passes reference for %term_log to &log_init
	log_init($t,$section,\%term_log);
}

sub log_init {
	my ($t,$section,$log) = @_;
	
	#uses the Elt hash ref as the key
	$log->{$section} = {
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
		$log->{$section}{'atts'}{$att} = [$val,0];
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

sub print_log {
	my (%log) = @_;
	
	foreach my $section (sort {$log{$a}{'line'} <=> $log{$b}{'line'}} keys %log) 

	{
	
		printf "%s of line %d is child of %s.",
		$log{$section}->{'name'},
		$log{$section}->{'line'},
		$log{$section}->{'parent'} ? $log{$section}->{'parent'} : 'root';
	
		while (my($att,$contents) = each $log{$section}{'atts'}) 
	
		{
			printf "\n%s has attribute %s:%s.",
			$log{$section}->{'name'},
			$att, $contents->[0],
			;
		}
	
		if ($log{$section}->{'text'}) 
		{
			printf "\n%s has text '%s'.",
			$log{$section}->{'name'},
			$log{$section}->{'text'},
			;
		} 
	
		print "\n\n";
	}
	
}

$file = $ARGV[0];

die "Provide a file!" unless ($file && $file =~ m/\.(tbx|xml|tbxm)\Z/ && -e $file);

my $twig = XML::Twig->new(
	
pretty_print 		=> 'indented',

output_encoding 	=> 'utf-8',

start_tag_handlers 	=> {
	
	_all_ 				=> \&aux_log_init,
	
},

twig_handlers 		=> {
	
	output_html_doctype =>1,
	
	_default_ 			=> \&test_all,
	
}
	
);

$twig->parsefile($file);

#print logfile sorted by linenumber of original
print_log(%aux_log);

$twig->purge();

