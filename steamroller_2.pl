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

#version 2.25 improves on the log output
#fixes trigger log message OVERHAUL

my $version = 2.25;

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

#hash of all allowed attributes by element
my %atts=(
'martif' 		  => ['type','xml:lang'],
'martifHeader' 	  => ["id"],
'fileDesc' 		  => ["id"],
'p' 			  => ["id",'type','xml:lang'],
'titleStmt' 	  => ["id",'xml:lang'],
'title' 		  => ["id",'xml:lang'],
'note' 			  => ["id",'xml:lang'],
'publicationStmt' => ["id"],
'sourceDesc'	  => ["id",'xml:lang'],
'encodingDesc' 	  => ["id"],
'revisionDesc' 	  => ["id",'xml:lang'],
'change' 		  => ["id",'xml:lang'],
'text' 			  => ["id"],
'body' 			  => ["id"],
'back' 			  => ["id"],
'refObjectList'   => ["id",'type'],
'refObject' 	  => ["id"],
'item' 			  => ["id",'type'],
'termEntry' 	  => [qw(id)],
'langSet' 		  => [qw(id xml:lang)],
'tig' 			  => [qw(id)],
'term' 			  => [qw(id)],
'termNote' 		  => [qw(id xml:lang type target datatype)],
'descrip' 		  => [qw(id xml:lang type target datatype)],
'descripGrp' 	  => [qw(id)],
'admin' 		  => [qw(id xml:lang type target datatype)],
'transacGrp' 	  => [qw(id)],
'note' 			  => [qw(id)],
'ref' 			  => [qw(id xml:lang type target datatype)],
'xref' 			  => [qw(id target type)],
'transac' 		  => [qw(id xml:lang type target datatype)],
'transacNote' 	  => [qw(id xml:lang type target datatype)],
'date' 			  => [qw(id)],
'hi' 			  => [qw(type target xml:lang)],
'foreign' 		  => [qw(id xml:lang)],
'bpt' 			  => [qw(i type)],
'ept' 			  => [qw(i)],
'ph' 			  => [qw(type)],
'#PCDATA' 		  => [qw()],
);

my %dump=(
'martif' 		  => [qw(sourceDesc last_child)], 	
'martifHeader' 	  => [qw(sourceDesc last_child)], 	
'fileDesc' 		  => [qw(sourceDesc last_child)], 	
'p' 			  => [qw(p after)],
'titleStmt' 	  => [qw(note last_child)],
'title' 		  => [qw(note after)],
'note' 			  => [qw(note after)],
'publicationStmt' => [qw(sourceDesc after)],			
'sourceDesc'	  => [qw(p last_child)],
'encodingDesc' 	  => [qw(p last_child)],	
'revisionDesc' 	  => [qw(p last_child)],    
'change' 		  => [qw(p last_child)],    
'text' 			  => [qw(sourceDesc before)],
'body' 			  => [qw(sourceDesc before)],
'back' 			  => [qw(item last_child)], 
'refObjectList'   => [qw(item last_child)], 
'refObject' 	  => [qw(item last_child)], 
'item' 			  => [qw(item after)],    
'termEntry' 	  => [qw(note last_child)], 
'langSet' 		  => [qw(note last_child)], 
'tig' 			  => [qw(note last_child)], 
'term' 			  => [qw(note after)],    
'termNote' 		  => [qw(note after)],    
'descrip' 		  => [qw(admin after)],   
'descripGrp' 	  => [qw(admin last_child)],
'admin' 		  => [qw(admin after)],   
'transacGrp' 	  => [qw(note after)],    
'note' 			  => [qw(note after)],    
'ref' 			  => [qw(note after)],    
'xref' 			  => [qw(note after)],    
'transac' 		  => [qw(note after)],    
'transacNote' 	  => [qw(note after)],
'date' 			  => [qw(note after)],
'hi' 			  => [qw(parent after)],
'foreign' 		  => [qw(parent after)],
'bpt' 			  => [qw(parent after)],
'ept' 			  => [qw(parent after)],
'ph' 			  => [qw(parent after)],
'#PCDATA' 		  => [qw(parent after)],
);

#hash of datcat values to the terms they match, used in dca_check
my %datcats = (
"TBX-Basic"					=> 'martif',
'administrativeStatus'		=> 'termNote',
'geographicalUsage'			=> 'termNote',
'grammaticalGender'			=> 'termNote',
'partOfSpeech'				=> 'termNote',
'termLocation'				=> 'termNote',
'termType'					=> 'termNote',
'context'					=> 'descrip',
'definition'				=> 'descrip',
'subjectField'				=> 'descrip',
'crossReference'			=> 'ref',
'externalCrossReference'	=> 'xref',                       	
'xGraphic'					=> 'xref',                                     	
'customerSubset'			=> 'admin',                              	
'projectSubset'				=> 'admin',
'source'					=> 'admin',
'responsibility'			=> 'transacNote',
'transactionType'			=> 'transac',
'DCSName'					=> 'p',
'XCSURI'					=> 'p',
'XCSContent'				=> 'p',    
'respPerson'				=> 'refObjectList',
'fn'						=> 'item',
'n'							=> 'item',
'nickname'					=> 'item',
'photo'						=> 'item', #item types imported from 
'bday'						=> 'item',	#https://tools.ietf.org/html/rfc6350
'anniversary'				=> 'item', #most left out to avoid
'gender'					=> 'item', #clogging up the algorithms 
'adr'						=> 'item', 
'tel'						=> 'item', 
'email'						=> 'item', 
'impp'						=> 'item',
'lang'						=> 'item', #future version should recognize these
'tz'						=> 'item', #as valid but not use them as guesses
'geo'						=> 'item',
'title'						=> 'item',
'role'						=> 'item',
'logo'						=> 'item',
'org'						=> 'item',
'member'					=> 'item',
'related'					=> 'item',
'categories'				=> 'item',
'prodid'					=> 'item',
'rev'						=> 'item',
'sound'						=> 'item',
'uid'						=> 'item',
'clientpidmap'				=> 'item',
'url'						=> 'item',
'version'					=> 'item',
'bold'						=> 'bpt',	   # = Bold                      
'ulined'					=> 'bpt',     # = Underline              
'dulined'					=> 'bpt',     # = Double-underlined      
'color'						=> 'bpt',     # = Color change           
'struct'					=> 'bpt',     # = XML/SGML structure
'italic'					=> 'bpt',     # = Italic
'scap'						=> 'bpt',     # = Small caps
'font'						=> 'bpt',     # = Font change
'link'						=> 'bpt',     # = Linked text
'index'						=> 'ph',	   # = Index marker          these are text     
'time'						=> 'ph',      # = Time                  markup tags
'enote'						=> 'ph',      # = End-note                 
'image'						=> 'ph',      # = Image                    
'lb'						=> 'ph',      # = Line break               
'inset'						=> 'ph',      # = Inset                        
'date'						=> 'ph',      # = Date
'fnote'						=> 'ph',      # = Footnote
'alt'						=> 'ph',      # = Alternate text
'pb'						=> 'ph',      # = Page break			bpt ph types inhereted from
);								

#guess from these if value invalid, to avoid spurrious 'color' elements
my @datguess = (
'administrativeStatus'		,
'geographicalUsage'			,
'grammaticalGender'			,
'partOfSpeech'				,
'termLocation'				,
'termType'					,
'context'					,
'definition'				,
'subjectField'				,
'crossReference'			,
'externalCrossReference'	,             
'xGraphic'					,             
'customerSubset'			,             
'projectSubset'				,
'source'					,
'responsibility'			,
'transactionType'			,
'DCSName'					,
'XCSURI'					,
'XCSContent'				,
'respPerson'				,
);

my %req_atts = (
'langSet'		=> ['check','xml:lang', 'und'], #'und' is ISO 639-2 for undetermined
'refObjectList' => ['check','type','respPerson'],
'admin'			=> ['check','type','source'],
'transacNote'	=> ['check','type','responsibility'],

'martif'		=> ['check','xml:lang', 'und',
					'set','type', 'TBX-BASIC'],


'termNote'		=> ['kill','type'],
'descrip'		=> ['kill','type'],
'transacSpec'	=> ['kill','type'],

'ref'			=> ['kill','type'],

'xref'			=> ['fix','target',
					'fix','type'],
					
'termEntry' 	=> ['fix','id'],
);

#intelligently stores disallowed data in a safe location nearby
sub dump_truck {
	#value is optional,used for atts
	my ($t,$section,$data,$value,$is_att,$log) = @_;
	
	my $text = sprintf "%s%s%s%s",
	$section->name(),
	$log->{$section} ? " (from line:".$log->{$section}{'line'}.") " : "",
	$data,
	$value ? "=".$value : "",;
	
	#should only be called on termEntry and martif if $is_att is true
	my $target = $is_att && defined $dump{$section->name()} ?
	$section : $section->parent();
	my ($fate,$position) = @{$dump{$target->name()}};
	
	if ($fate eq 'parent') {
		
		$target = $target->parent();
		($fate,$position) = @{$dump{$target->name()}};
	}
	
	my $message = $fate;
	
	if ($fate eq 'sourceDesc') {
		my $sd = XML::Twig::Elt->new($fate);
		my $temp = XML::Twig::Elt->new('p' => $text);
		$temp->paste($sd);
		$sd->paste($position => $target);
		$message = "SOURCEDESC";
	}
	
	elsif ($fate eq 'admin') {
		my $temp = XML::Twig::Elt->new($fate => {type => 'source'} => $text);		
		$temp->paste($position => $target);
	}
	
	else
	
	{
		
		my $temp = XML::Twig::Elt->new($fate => $text);
		$temp->paste($position => $target);
		
	}
	
	#adds special log message for bad DCA data
	if ($data eq 'Data:') {
		$message.="_DATA";
	}
	
	if ($is_att) {
		#$log->{$section}{'atts'}{$data}[1]="INV_".$message;
		$log->{$section}{'atts'}{$data}{'code'} = "INVALID";
		$log->{$section}{'atts'}{$data}{'a_fate'} = $fate;
	}
	
	else
	
	{
		#$log->{$section}{'n_fate'}="INV_".$message;
		$log->{$section}{'n_code'}=
		$value ? "BADCAT" : "RENAME";
		$log->{$section}{'n_fate'}=$fate; #for now
	}
	
}

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
		'n_code'	=> 0,
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
		$log->{$section}{'atts'}{$att} = {
			'val' 		=> $val,
			'v_fate'	=> 0,
			'code'		=> 0,
			'a_fate'	=> 0,
		};
	}
	
	return 1;
	
}

sub autocorrect {
	#optional condition for special circumstances, pass true to ignore
	my ($target,$prefer,$option,$tolerance,$condition) = @_;
	
	my %relevance = map {$_ => similarity lc $target, lc $_} (@{$prefer},@{$option});
	
	my @j = (
	(reverse sort {$relevance{$a} <=> $relevance{$b}} @{$prefer}),
	(reverse sort {$relevance{$a} <=> $relevance{$b}} @{$option}));
	
	foreach my $guess (@j) 
	
	{
		
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
		$log->{$section}{'n_code'} = "RENAME";
		
		return 1;
	}
	
	return 0;
	
}

sub att_check {
	
	my ($t,$section,$att,$log) = @_;
	
	my $cname = $section->name();
	
	if (grep {$att eq $_} @{$atts{$cname}}) {
		
		return 1;
	}
	
	if (my $guess = autocorrect($att,$atts{$cname},[],.5,1)) {
		
		$section->change_att_name($att,$guess);
		
		#log the att if it was there originally
		if ($log->{$section}{'atts'}{$att}) {
			$log->{$section}{'atts'}{$att}{'code'}="RENAME";
			$log->{$section}{'atts'}{$att}{'a_fate'}=$att;
			$log->{$section}{'atts'}{$guess}= delete $log->{$section}{'atts'}{$att};
		}
		
		
		return $guess;
	} 
	
	return 0;
	
}

#checks to make sure required attributes found in @req_atts are present
sub prereq {
	
	my ($t,$section,$log) = @_;
	
	my $cname = $section->name();
	
	return 1 unless $req_atts{$cname};
	
	my @exec = @{$req_atts{$cname}};
	
	while (my $com = shift @exec) {
		if ($com eq 'kill') {
			my $att = shift @exec;
			unless ($section->att($att)) {
				
				if ($section->text(no_recurse=>1)) {
					dump_truck($t,$section,"missing attribute $att",
					$section->text(no_recurse=>1),0,$log);
					$section->first_child("#PCDATA")->delete();
					#causes pretty print issues with marked up pcdata
				}
		
				while (my ($a,$b) = each $section->atts()) {
					dump_truck($t,$section,$a,$b,1,$log);
				}
				
				$section->erase();
				
			}
		} 
		elsif ($com eq 'check') {
			my $att = shift @exec;
			my $guess = shift @exec;
			unless ($section->att($att)) {
				$section->set_att($att=>$guess);
				$log->{$section}{'atts'}{$att}{'code'}="MISSING";
				$log->{$section}{'atts'}{$att}{'v_fate'}=$guess;
			}
		}
		elsif ($com eq 'fix') {
			my $att = shift @exec;
			unless ($section->att($att)) {
				#all fixes are special cases
				if ($att eq 'id') {
					$section->add_id();
					$log->{$section}{'atts'}{'id'}{'v_fate'}=$section->att('id');
					$log->{$section}{'atts'}{'id'}{'code'}="MISSING";
				}
				elsif ($att eq 'target') 
				{
					#umm...in one bad tbx, the target was just the text
					if ($section->text() =~ m/\.\w{3,}$/) {
						$section->set_att(target=>$section->text());
						$log->{$section}{'atts'}{'target'}{'v_fate'}=$section->text();
						$log->{$section}{'atts'}{'target'}{'code'}="MISSING";
					} else {
						#destroy it!
						if ($section->text(no_recurse=>1)) {
							dump_truck($t,$section,"missing attribute $att",
							$section->text(no_recurse=>1),0,$log);
							$section->first_child("#PCDATA")->delete();
							#causes pretty print issues with marked up pcdata
						}
		
						while (my ($a,$b) = each $section->atts()) {
							dump_truck($t,$section,$a,$b,1,$log);
						}
					}
				}
				elsif ($att eq 'type') 
				{
					if ($section->att('target') =~ m/\.(jpg|png|gif|svg)$/) {
						$section->set_att('type'=>'xGraphic');
						$log->{$section}{'atts'}{'type'}{'code'}="MISSING";
						$log->{$section}{'atts'}{'type'}{'v_fate'}='xGraphic';
					}
					else
					{
						$section->set_att('type'=>'externalCrossReference');
						$log->{$section}{'atts'}{'type'}{'v_fate'}=
						'externalCrossReference';
						$log->{$section}{'atts'}{'type'}{'code'}="MISSING";
					}
				}
			}
		}
		elsif ($com eq 'set') {
			my $att = shift @exec;
			my $val = shift @exec;
			if ($section->att($att)) {
				unless (lc $section->att($att) eq lc $val)
				
				{
					$section->set_att($att=>$val);
					$log->{$section}{'atts'}{$att}{'v_fate'}=$val;
					$log->{$section}{'atts'}{$att}{'code'}=
					$log->{$section}{'atts'}{$att}{'code'} eq "RENAME" ?
					"OVERHAUL": "REVAL";
				}
				
			}
			else
			{
				$section->set_att($att=>$val);
				$log->{$section}{'atts'}{$att}{'v_fate'}=$val;
				$log->{$section}{'atts'}{$att}{'code'}="MISSING";
				
			}
		}
	}
	
	return 1;
	
}

sub dca_check {
	
	my ($t,$section,$log) = @_;
    
	return 1 unless my $value = $section->att('type');
	
	my $cname = $section->name();
	#printf "Name %s Value %s\n",$cname, $value;
	
	if (grep {$value eq $_} keys %datcats) {
		
		##match_correct();
		
		return 1;
		
	}
	
	if (my $guess = autocorrect($value,\@datguess,[],.5,1)) {
		
		#printf "Name %s Value %s Guess %s\n",$cname, $value, $guess;
		
		$section->set_att(type => $guess);
		
		if ($log->{$section}{'atts'}{'type'}) {
			$log->{$section}{'atts'}{'type'}{'code'}=
			$log->{$section}{'atts'}{'type'}{'code'} eq "RENAME" ?
			"OVERHAUL": "REVAL";
			$log->{$section}{'atts'}{'type'}{'v_fate'}=$guess;
		}
		
		###match_correct();
		
		return 1;
		
	}
	
	#printf "!!Name %s Value %s\n",$cname, $value;
	
	return 0;
	
}

sub term_log_init {
	my ($t,$section) = @_;
	#passes reference for %term_log to &log_init
	#print $section->name(),' ',$section,"\n";
	log_init($t,$section,\%term_log);
	
	return 1;
}

sub handle_term {
	my ($t,$section) = @_;
	
	$term_log{$section}{'text'}=$section->children_text('#PCDATA');
	$term_log{$section}{'text'} =~ s/\s+/ /g;
	
	unless (name_check(@_,\%term_log)) 
	#Abandon ship! No name found, destroy element
	{

		dump_truck($t,$section,'(invalid name)','',0,\%term_log);
		while (my ($a,$b) = each $section->atts()) {
			dump_truck($t,$section,$a,$b,1,\%term_log);
		}
		
	
		$section->erase();
		
		return 1;
		
	}
	
	foreach my $att (keys $section->atts()) {
		#check that the att is TBX approved
		unless (att_check(@_,$att,\%term_log)) 
		{
			dump_truck($t,$section,$att,$section->att($att),1,\%term_log);

			$section->del_att($att);
			
		}
	}
	
	prereq($t,$section,\%term_log);
	
	unless (dca_check($t,$section,\%term_log)) {
		
		
		if ($section->text(no_recurse=>1)) {
			dump_truck($t,$section,'Data:',
			$section->text(no_recurse=>1),0,\%term_log);
			$section->first_child("#PCDATA")->delete();
			#causes pretty print issues with marked up pcdata
		}
		
		while (my ($a,$b) = each $section->atts()) {
			dump_truck($t,$section,$a,$b,1,\%term_log);
		}
		
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
		dump_truck($t,$section,'(invalid name)','',0,\%aux_log);
		while (my ($a,$b) = each $section->atts()) {
			dump_truck($t,$section,$a,$b,1,\%term_log);
		}
		
		$section->erase();
		
		
	}
	
	foreach my $att (keys $section->atts()) {
		#check that the att is TBX approved
		unless (att_check(@_,$att,\%aux_log)) 
		{
			dump_truck($t,$section,$att,$section->att($att),1,\%aux_log);
			
			$section->del_att($att);
			
		}
	}
	prereq($t,$section,\%aux_log);
	
	unless (dca_check($t,$section,\%aux_log)) {
		
		
		if ($section->name() eq 'martif') {
			$section->set_att(type=>"TBX-Basic");
			#TEMPORARY MEASURE
		}
		else
		{
			if ($section->text(no_recurse=>1)) {
				dump_truck($t,$section,'Data:',
				$section->text(no_recurse=>1),0,\%aux_log);
				$section->first_child("#PCDATA")->delete();
				#causes pretty print issues with marked up pcdata
			}
			
			while (my ($a,$b) = each $section->atts()) {
				dump_truck($t,$section,$a,$b,1,\%aux_log);
			}
			$section->erase();
		}
		
		
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
	
	my $clean = 1;
	my @sections = sort {$log{$a}{'line'} <=> $log{$b}{'line'}} keys %log;
	foreach my $section (@sections) 

	{
		#declare item to output for section at hand
		my $i = '';
		#print $log{$section}->{'name'},"\n";
		if ($verbose) 
		{
			$i .= sprintf "%s of line %d was child of %s.\n",
			$log{$section}->{'name'},
			$log{$section}->{'line'},
			$log{$section}->{'parent'} ? $log{$section}->{'parent'} : 'root';
		}
		
		if (my $fate = $log{$section}->{'n_code'}) {
			
			if ($fate eq 'BADCAT') {
				my $x;
				$i .= sprintf "%s had bad data category%s. Stored as %s.\n",
				$log{$section}->{'name'},
				($x = $log{$section}{'atts'}{'type'}{'val'}) ? " '$x'" : '',
				$log{$section}->{'n_fate'};
			}
			
			elsif ($fate eq 'INVALID') {
				$i .= sprintf "%s had invalid name. Stored as %s.\n",
				$log{$section}->{'name'},$log{$section}->{'n_fate'};
			}
			
			elsif ($fate eq 'RENAME') {
				$i .= sprintf "%s had invalid name, renamed %s.\n",
				$log{$section}->{'name'},$log{$section}->{'n_fate'};
			}
			
		}
	
		foreach my $att (sort keys $log{$section}{'atts'}) 

		{
			my $contents = $log{$section}{'atts'}{$att};
			$i .= sprintf "%s has attribute %s:%s.\n",
			$log{$section}->{'name'},
			$att, $contents->[0],
			if $verbose;
			if (my $code = $contents->{'code'}) {
				if ($code eq "MISSING") {
					$i .= sprintf "!Attribute %s missing, set to '%s'.\n",
					$att, $contents->{'v_fate'};
				}
				elsif ($code eq "INVALID") {
					$i .= sprintf "!!Attribute %s=%s was invalid, stored as %s.\n",
					$att, $contents->{'val'}, $contents->{'a_fate'};
				}
				elsif ($code eq "REVAL") {
					$i .= sprintf "!!!'%s' value '%s' invalid, changed to '%s'.\n",
					$att, $contents->{'val'}, $contents->{'v_fate'};
				}
				elsif ($code eq "RENAME") {
					$i .= sprintf "!!!!Attribute name '%s' invalid, changed to '%s'.\n",
					$contents->{'a_fate'},$att;
				}
				elsif ($code eq "OVERHAUL") {
					$i .= sprintf "!!!!!Attribute %s=%s changed to %s=%s.\n",
					$contents->{'a_fate'}, $contents->{'val'},
					$att, $contents->{'v_fate'};
				}
				else {
					$i .= sprintf "Unknown Error on $att.\n";
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
			$clean = 0;
		}
		
	}
	
	printf $lf "%s on line %s is clean.\n\n",
	$log{$sections[0]}->{'name'},
	$log{$sections[0]}->{'line'},
	if $clean;
	
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

$twig->set_id_seed('c');

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