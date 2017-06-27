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

#version 2.11 implements verbose logging options
my $version = 2.11;

#changes behaviour if true, used for coding purposes
my $dev = 1;
my $verbose = 0;

#initialize file;
my $file;

my $test_counter=0;

#open termEntry and log files
open (my $tft,'>','temp_file_text.txt');
open (my $lf,'>','log_steamroller.txt');

my %aux_log;
my %term_log;

#initialize variables which store elements as they are encountered, used later for rearrangement
my(
$martif,
$martifHeader,
$fileDesc,
@p,
$titleStmt,
$title,
@note,
$publicationStmt,
@sourceDesc,
$encodingDesc,
$revisionDesc,
@change,
@pcdata,
$text,
$body,
$back,
@refObjectList,
@refObject,
@item,
$placeholder,
@termEntry,
@langSet,
@tig,
@term,
@termNote,
@descrip,
@descripGrp,
@admin,
@transacGrp,
@ref,
@xref,
@transac,
@transacNote,
@date,
@hi,
@foreign,
@bpt,
@ept,
@ph,
);

#hash of element names to the reference for their corresponding variable
my %refs=(
'martif' => \$martif,
'martifHeader' => \$martifHeader,
'fileDesc' => \$fileDesc,
'p' =>\@p, 
'titleStmt' => \$titleStmt,
'title' => \$title,
'note' => \@note,
'publicationStmt' => \$publicationStmt,
'sourceDesc' => \@sourceDesc,
'encodingDesc' => \$encodingDesc,
'revisionDesc' => \$revisionDesc,
'change' => \@change,
'#PCDATA' => \@pcdata,
'text' => \$text,
'body' => \$body,
'back' => \$back,
'refObjectList' => \@refObjectList,
'refObject' => \@refObject,
'item' => \@item,
'placeholder' => \$placeholder,
'termEntry' => \@termEntry,
'langSet' => \@langSet,
'tig' => \@tig,
'term' => \@term,
'termNote' => \@termNote,
'descrip' => \@descrip,
'descripGrp' => \@descripGrp,
'admin' => \@admin,
'transacGrp' => \@transacGrp,
'ref' => \@ref,
'xref' => \@xref,
'transac' => \@transac,
'transacNote' => \@transacNote,
'date' => \@date,
'hi' => \@hi,
'foreign' => \@foreign,
'bpt' => \@bpt,
'ept' => \@ept,
'ph' => \@ph,
);

my %comp=(
0 => ['martif'],
'martif' => ['martifHeader','text'],
'martifHeader' => ['fileDesc','encodingDesc','revisionDesc'],
'fileDesc' => ['titleStmt','publicationStmt','sourceDesc'],
'p' => ['#PCDATA'],
'titleStmt' => ['title','note'],
'title' => ['#PCDATA'],
'publicationStmt' => ['p'],
'sourceDesc' => ['p'],
'encodingDesc' => ['p'],
'revisionDesc' => ['change'],
'change' =>	['p'],
'text' => ['body','back'],
'body' => ['termEntry'],
'back' => ['refObjectList'],
'refObjectList' => ['refObject'],
'refObject' => ['item'],
'item' => ['#PCDATA','hi','foreign','bpt','ept','ph'],
'termEntry' => [qw(langSet descrip descripGrp admin transacGrp note ref xref)],
'langSet' => [qw(tig descrip descripGrp admin transacGrp note ref xref)],
'tig' => [qw(term termNote descrip descripGrp admin transacGrp note ref xref)],
'term' => ["#PCDATA", qw(hi)],
'termNote' => ["#PCDATA", qw(hi foreign bpt ept ph)],
'descrip' => ["#PCDATA", qw(hi foreign bpt ept ph)],
'descripGrp' => [qw(descrip admin)],
'admin' => ["#PCDATA", qw(hi foreign bpt ept ph)],
'transacGrp' => [qw(transac transacNote date)],
'note' => ["#PCDATA", qw(hi foreign bpt ept ph)],
'ref' => ["#PCDATA"],
'xref' => ["#PCDATA"],
'transac' => ["#PCDATA", qw(hi foreign bpt ept ph)],
'transacNote' => ["#PCDATA", qw(hi foreign bpt ept ph)],
'date' => ["#PCDATA"],
'hi' => ["#PCDATA"],
'foreign' => ["#PCDATA", qw(hi foreign bpt ept ph)],
'bpt' => ["#PCDATA"],
'ept' => ["#PCDATA"],
'ph' => ["#PCDATA"],
);

sub store {
	
	my $item = $_[0];
	
	#Retrieves the reference to the named variable
	my $ref=$refs{$item->name()};
	
	
	if (ref($ref) eq 'ARRAY') 
	
	#If ARRAY, then the element may be duplicated, push reference to array
	{
		push @{$ref}, $item; 
	} 
	
	elsif (ref($ref) eq 'SCALAR') 
	
	#SCALAR means the element should be unique, but is not taken yet.
	{
		${$ref} = $item;
	} 
	
	elsif (ref($ref) eq 'REF') 
	
	#REF means the element's reference is filled, and must be unique.
	#returns 0 to indicate failure to store, element will be renamed.
	{
		return 0;		
	} 
	
	else 
	#The element was not in the hash of refs; should never be trigged.
	{
		die "Unhandled type ".$item->name().' '.ref($ref)."\n";
	}
	
	#Indicates success, triggered when ref was ARRAY or SCALAR
	return 1;
	
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

sub autocorrect {
	#optional condition for special circumstances, pass true to ignore
	my ($target,$prefer,$option,$tolerance,$condition) = @_;
	#printf "target %s prefer %d %s option %d %s\n",
	#$target,$#{$prefer},$prefer,$#{$option},$option;
	
	my %relevance = map {$_ => similarity $target, $_} (@{$prefer},@{$option});
	
	#while (my ($a,$b) = each %relevance) {
	#	print $a,$b,"\n";
	#}
	
	#makes list sorted by validity, with preferred first, options after
	my @j = (
	(reverse sort {$relevance{$a} <=> $relevance{$b}} @{$prefer}),
	(reverse sort {$relevance{$a} <=> $relevance{$b}} @{$option}));
	
	foreach my $guess (@j) 
	
	{
		#printf "target %s guess %s score %s\n",$target,$guess,$relevance{$guess};
		if ($relevance{$guess}>$tolerance and eval($condition))
		{
			return $guess;
		}
	}
	
	return 0;
				
}

sub name_check {
	my ($t,$section,$log) = @_;
	
	#make sure that the name is one of the allowed names
	
	my $cname = $section->name();
	my $pname = $section->level()>0 ? $section->parent()->name() : 0;
	
	if (grep {$cname eq $_} keys %comp)
	
	{
		if (store($section))
		{
			return 1;
		}
	}
	
	if (my $guess = autocorrect($cname,$comp{$pname},[keys %refs],.5,
	'ref($refs{$guess}) ne "REF"'))
	
	{
		$section->set_name($guess);
		store($section);
		
		$log->{$section}{'n_fate'} = $guess;
		
		return 1;
	}
	
	return 0;
	
}

sub term_log_init {
	my ($t,$section) = @_;
	#passes reference for %term_log to &log_init
	log_init($t,$section,\%term_log);
	
	return 1;
}

sub handle_term {
	my ($t,$section) = @_;
	
	$term_log{$section}{'text'}=$section->children_text('#PCDATA');
	$term_log{$section}{'text'} =~ s/\s+/ /g;
	
	unless (name_check(@_,\%term_log)) 
	
	{
		#my $cname = $section->name();
		
		my ($a,$b) = ('Original Name',$section->name());
		#store original name as note, as well as all atts
		do 
		{
			my $temp = XML::Twig::Elt->new('note' =>$a."=".$b);
			$temp->paste(before=>$section);
			store($temp);
			
			$term_log{$section}{'atts'}{$a}[1]='NOTE' unless $a eq 'Original Name';
		} 
		while (($a,$b) = each $section->atts());
		$term_log{$section}{'n_fate'}='INVALID';
		$section->erase();
		
	}
	
	return 1;
}

sub order_term {
	my ($t,$section) = @_;
	
	handle_term(@_);
	
	#print the log for term entries
	print_log(%term_log);
	
	#clear log and memory
	%term_log=();
	$section->print($tft);
	$section->delete();
	#wipe(); #activate when we start actually doing crap with these
	return 1;
}

sub aux_log_init {
	my ($t,$section) = @_;
	#passes reference for %aux_log to &log_init
	log_init($t,$section,\%aux_log);
	
	return 1;
}

sub handle_aux {
	my ($t,$section) = @_;
	
	$aux_log{$section}{'text'}=$section->children_text('#PCDATA');
	$aux_log{$section}{'text'} =~ s/\s+/ /g;

	unless (name_check(@_,\%aux_log)) 
	
	{
		my $id = $section->att("id") ? 
		
		#then keep it and append the old name in parentheses
		$section->att("id")." (".$section->name().")" :
		
		#otherwise, just set the id to the original name
		$section->name();
		$section->set_att("id"=>$id);
		
		#for aux items, make sourceDesc, which is made for this kind of info
		$section->set_name("sourceDesc");
		
		#capitals to trigger special message
		$aux_log{$section}{'n_fate'}='SOURCEDESC';
		
		#store it. will not fail because sourceDesc is stackable
		store($section);
	}
	
	return 1;
}

sub order_root {
	my ($t,$section) = @_;
	
	handle_aux(@_);
	return 1;
}

sub print_log {
	my (%log) = @_;
	
	foreach my $section (sort {$log{$a}{'line'} <=> $log{$b}{'line'}} keys %log) 

	{
		#declare item to output for section at hand
		my $i = '';
		
		if ($verbose) 
		{
			$i .= sprintf "%s of line %d was child of %s.\n",
			$log{$section}->{'name'},
			$log{$section}->{'line'},
			$log{$section}->{'parent'} ? $log{$section}->{'parent'} : 'root';
		}
		
		if (my $fate = $log{$section}->{'n_fate'}) {
			if ($fate eq 'SOURCEDESC') 
			#invalid name in auxilliary
			{
				$i .= sprintf "%s had invalid name. Stored in a sourceDesc.\n",
				$log{$section}->{'name'};
			}
			elsif ($fate eq 'INVALID') 
			#invalid name in termEntry
			{
				$i .= sprintf "%s had invalid name. Stored as note.\n",
				$log{$section}->{'name'};
			}
			else
			#the standard case
			{
				$i .= sprintf "%s was renamed to %s.\n",
				$log{$section}->{'name'},
				$fate;
			}
		}
	
		while (my($att,$contents) = each $log{$section}{'atts'}) 
	
		{
			$i .= sprintf "%s has attribute %s:%s.\n",
			$log{$section}->{'name'},
			$att, $contents->[0],
			if $verbose;
			if (my $fate = $contents->[1]) {
				if ($fate eq 'NOTE') {
					$i .= sprintf "Attribute %s=%s stored as note.\n",
					$att,$contents->[0];
				}
				else
				{
					#other conditions
				}
				
			}
		}
	
		if ($log{$section}->{'text'}) 
		{
			$i .= sprintf "%s has text '%s'.\n",
			$log{$section}->{'name'},
			$log{$section}->{'text'},
			if $verbose;
		} 
	
		if ($i) {
			printf $lf "%s on line %d:\n",
			$log{$section}->{'name'},
			$log{$section}->{'line'},
			unless $verbose;
			print $lf $i,"\n";
		}
		
	}
	
}

$file = $ARGV[0];

die "Provide a file!" unless ($file && $file =~ m/\.(tbx|xml|tbxm)\Z/ && -e $file);

my $twig = XML::Twig->new(
	
pretty_print 		=> 'indented',

output_encoding 	=> 'utf-8',

start_tag_handlers 	=> {
	
	"termEntry"			=> \&term_log_init,
	
	"termEntry//*" 		=> \&term_log_init,
	
	_default_ 			=> \&aux_log_init,
	
},

twig_handlers 		=> {
	
	output_html_doctype =>1,
	
	"termEntry//*"		=> \&handle_term,
	
	"termEntry"			=> \&order_term,
	
	_default_ 			=> \&handle_aux,
	
	"/*" 				=> \&order_root,
	
}
	
);

$twig->parsefile($file);

#print logfile sorted by linenumber of original
print_log(%aux_log);

my $auxilliary = $twig->sprint();

close($tft);
open($tft,'<','temp_file_text.txt');

my $out_name = $file;
$out_name =~ s/(.+?)\..+/$1_steamroller.tbx/;
$out_name = 'result.tbx' if $dev;

open(my $out, ">:encoding(UTF-8)",$out_name);

foreach my $line (split(/\n/,$auxilliary)) {
	if ($line =~ m!<body></body>!) 
	
	#this gross code will be nicer when placeholder is back
	
	{
		
		$line =~ s!</body>!!;
		print $out $line,"\n";
		
		while (<$tft>) 
		{
			print $out "$_" if ($_ ne "\n");
		}
		
		$line =~ s!<body>!</body>!;
		print $out "\n",$line;
		
	}
	
	else 
	
	{
		print $out $line;
	}
	
	print $out "\n";
}