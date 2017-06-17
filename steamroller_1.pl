use warnings;
use strict;
use XML::Twig;
use String::Similarity;

#if $version is greater than 0.1, the steamroller will delete temporary files
#and add a brand marker to identify the file as a steamroller-generated file.
my $version = 0.2;

#determines how close an element name guess must be to rename a bad element.
my $tolerance = 0.4;

#steamroller 0.2 adds data category specification compliance control

#opens file $tft to store termEntry elements
open (my $tft,'>','temp_file_text.txt'); 

#variables which store elements as they are encountered, used later for rearrangement
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

#hash of element compatibility, parent to child
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

#a list of elements which do not occur in a termEntry
my @aux_items=(
'martif' ,
'martifHeader' ,
'fileDesc' ,
'p' ,
'titleStmt' ,
'title' ,
'publicationStmt' ,
'sourceDesc' ,
'encodingDesc' ,
'revisionDesc' ,
'change' ,
'text' ,
'back' ,
'refObjectList' ,
'refObject' ,
); 

#hash of element compatibiity, child to possible parents
my %renp=(
'martifHeader'    => 'martif',
'text'            => 'martif',
'fileDesc'        => 'martifHeader',
'encodingDesc'    => 'martifHeader',
'revisionDesc'    => 'martifHeader',
'titleStmt'       => 'fileDesc',
'publicationStmt' => 'fileDesc',
'sourceDesc'      => 'fileDesc',
'title'           => 'titleStmt',
'note'            => 'titleStmt',
'change'          => 'revisionDesc',
'p'               => ['publicationStmt','sourceDesc','encodingDesc','change'],
'#PCDATA'         => ['title','note','p','item'],
'body'            => 'text',
'back'            => 'text',
'termEntry'       => 'body',
'placeholder'     => 'body',
'refObjectList'   => 'back',
'refObject'       => 'refObjectList',
'item'            => 'refObject',
'termEntry' 	  => [qw()],
'langSet' 		  => [qw(termEntry)],
'tig' 			  => [qw(langSet)],
'term' 			  => [qw(tig)],
'termNote' 		  => [qw(tig)],
'descrip' 		  => [qw(termEntry langSet tig descripGrp)],
'descripGrp' 	  => [qw(termEntry langSet tig)],
'admin' 		  => [qw(termEntry langSet tig descripGrp)],
'transacGrp' 	  => [qw(termEntry langSet tig)],
'note' 			  => [qw(termEntry langSet tig)],
'ref' 			  => [qw(termEntry langSet tig)],
'xref' 			  => [qw(termEntry langSet tig)],
'transac' 		  => [qw(termEntry langSet tig transacGrp)],
'transacNote' 	  => [qw(transacGrp)],
'date' 			  => [qw(transacGrp)],
'hi' 			  => [qw(term termNote descrip admin note transac transacNote foreign)],
'foreign' 		  => [qw(termNote descrip admin note transac transacNote foreign)],
'bpt' 			  => [qw(termNote descrip admin note transac transacNote foreign)],
'ept' 			  => [qw(termNote descrip admin note transac transacNote foreign)],
'ph' 			  => [qw(termNote descrip admin note transac transacNote foreign)],
'#PCDATA' 		  => [qw(term termNote descrip admin note ref
					xref transac transacNotedate hi foreign bpt ept ph)],
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

#a hash used in processing terms, which indicates
#the type of PCDATA acceptable in various elements.
my %pcstorage = (
'termEntry'=>'note',#best choice?
'langSet'=>'note',
'tig'=>'note',
'transacGrp'=>'transacNote',
'descripGrp'=>'admin',
'descrip'=>0,
'admin'=>0,
'term'=>0,
'termNote'=>0,
'xref'=>0,
'ref'=>0,
'note'=>0,
'transac' 	   =>0,
'transacNote'  =>0,
'date' 		   =>0,
'hi' 		=>0,
'foreign' 	=>0,
'bpt' 		=>0,
'ept' 		=>0,
'ph' 		=>0,
'#PCDATA' 	=>0,
'p'			=>0,
);

#stores an ELT object into a variable by the %refs hash above.
sub store {
	
	my $item = $_[0];
	my $ref=$refs{$item->name()};
	
	if (ref($ref) eq 'ARRAY') {
		push @{$ref}, $item; 
	} elsif (ref($ref) eq 'SCALAR') {
		${$ref} = $item;
	} elsif (ref($ref) eq 'REF') {
		return 0;		
	} else {
		die "Unhandled type ".$item->name().' '.ref($ref)."\n";
	}
	
	return 1;
	
}

#clears variables used in processing termEntry elements, so that large files don't leak memory
sub wipe {
	#cuts memory usage to a 1/3 of otherwise... not terrible
	@note = ();
	@termEntry = ();
	@langSet = ();
	@tig = ();
	@term = ();
	@termNote = ();
	@descrip = ();
	@descripGrp = ();
	@admin = ();
	@transacGrp = ();
	@ref = ();
	@xref = ();
	@transac = ();
	@transacNote = ();
	@date = ();
	@hi = ();
	@foreign = ();
	@bpt = ();
	@ept = ();
	@ph = ();
}

my %concomp = (
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
#'photo'					=> 'item', #item types imported from 
#'bday'						=> 'item',	#https://tools.ietf.org/html/rfc6350
#'anniversary'				=> 'item', #most left out to avoid
#'gender'					=> 'item', #clogging up the algorithms 
'adr'						=> 'item', 
'tel'						=> 'item', 
'email'						=> 'item', 
#'impp'						=> 'item',
#'lang'						=> 'item', #future version should recognize these
#'tz'						=> 'item', #as valid but not use them as guesses
#'geo'						=> 'item',
'title'						=> 'item',
'role'						=> 'item',
#'logo'						=> 'item',
#'org'						=> 'item',
#'member'					=> 'item',
#'related'					=> 'item',
#'categories'				=> 'item',
#'prodid'					=> 'item',
#'rev'						=> 'item',
#'sound'					=> 'item',
#'uid'						=> 'item',
#'clientpidmap'				=> 'item',
#'url'						=> 'item',
#'version'					=> 'item',
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
);									   # http://www.ttt.org/oscarstandards/tmx/tmxnotes.htm


#allowed picklist values for the given constraints

my %picklist = (
"administrativeStatus"		=> [qw( preferredTerm-admn-sts
					  				admittedTerm-admn-sts
					  				deprecatedTerm-admn-sts
					  				supersededTerm-admn-sts)],
                               
"grammaticalGender"	  		=> [qw( masculine feminine
					  				neuter other)],
                      		   
"partOfSpeech"		  		=> [qw( noun verb adjective
					  				adverb properNoun other)],
                      		   
"termType"			  		=> [qw( abbreviation acronym fullForm
									shortForm variant phrase)],
);

#allowed levels for the given constraints
my %levels = (
'context'=>['tig'],
'definition'=>['langSet','termEntry'],
'subjectField'=>['termEntry'],
);

sub constraint {
	#takes one argument, an element
	my ($section) = @_;
	
	#proceed 
	
	if (my $type = $section->att('type')) {
		
		#ignore the martif
		return 0 if ($section->name() eq 'martif');
		
		#print $type,"\n";
		
		if (grep {$type eq $_} keys %concomp) {
			
			if ($concomp{$type} eq $section->name()) {
#				print "No change '",$section->name(),"' type $type \n";
				return 0;
			}
			
#			print "Element '",$section->name(),"' type $type changed to ",$concomp{$type},"\n";
			return $type;
			#gives correct element for data category
			
			
		} 
		
		#same code as used in namecheck, perhaps good for consolidation
		
		my %relevance = map {$_ => similarity $type,$_} keys %concomp;
	
		my @j = (reverse sort {$relevance{$a} <=> $relevance{$b}} keys %relevance);
	
		foreach my $guess (@j) {
		
			#check if guess is worth listening to
			#print $guess.' '.$relevance{$guess}.' ';
			if ($relevance{$guess}>$tolerance) {
				#print "\n",$type, "\t",$relevance{$guess},"\t $guess","\n";
#				print "'",$section->name(),"' type $type changed to $guess ",$concomp{$guess},"\n";
				return $guess;
			
			}
		
		}
		
	}
	
	else {
#		print $section->name()," is N/A.\n";
		return 0;
		
	}
}

#processes a termElement, wherever encountered.
sub handle_term {
	
	my ($t,$section) = @_;
###	wipe();
	#check attributes
	$section->add_id() unless $section->att('id');
	
	foreach my $m ($section->att_names()) {
		
		unless (grep {$m eq $_} @{$atts{$section->name()}}) {
			
			my $value = $section->att($m);
			my $temp = XML::Twig::Elt->new('p'=>$value);
			$temp->set_att("id"=>$m);
			$temp->paste(last_child=>$section);
			store($temp);
			$section->del_att($m);
		}
	}
	
	#perform name and attribute check for all children of the termEntry
	my @children = $section->children();
	my $child;
	
	#name check for each child
	while ($child = shift @children) {
		
		unless (name_check($t,$child)) {
			
			my $cname=$child->name();
			#for aux items, make note, which can hold this kind of info
			$child->set_name("note");
			my $temp = XML::Twig::Elt->new(PCDATA => $cname);
			#$temp->set_att('id' => 'steamroller');
		
			$temp->paste(last_child => $child);
		
			#store it. will not fail because note is stackable
			store($section);
		}

		foreach my $m ($child->att_names()) {
			
			unless (grep {$m eq $_} @{$atts{$child->name()}}) {
				
				my $value = $child->att($m);
				my $temp = XML::Twig::Elt->new('p'=>$value);
				$temp->set_att("id"=>$m);
				$temp->paste(last_child=>$child);
				store($temp);
				$child->del_att($m);
			}
		}
		
		push @children, $child->children() if ($child->name() ne "text");
		
	}	 
	
	#now reorder the elements of the termEntry
	
	@children = $section->children();
	
	while ($child = shift @children) {
		
		my $cname = $child->name();
		
		my $pname = $child->parent()->name();
		
		unless (grep{$cname eq $_} @{$comp{$pname}}) {
			#within this bracket, only misplaced things enter
#			print $cname,' ', $pname, ' ',$pcstorage{$pname},"\n";
			
			#handle things that only contain text
			
			if ($cname eq "#PCDATA") {
				my $temp = XML::Twig::Elt->new('p'=>$child->text());
				$temp->replace($child);
				
				push @children,$temp;
			}
			
			elsif (not $pcstorage{$cname}) {
				
				my $fate = $pcstorage{$pname};
				
				if (not $fate or $cname eq 'xref') 
				#the current parent cannot have element children
				#or it contains important data?
				
				#simple move the element up and try again
				
				{
					
					$child->move(last_child=>$child->parent()->parent());
					
					#return to the list
					
					push @children,$child;
					
				}
				
				else
				
				#rename it to be something that works
				
				{
########					print $child->name(),' ',$fate,"\n";
					$child->set_name($fate);
					
				}
				
			}
			
			#handle other term elements                 
			                                            
			else {                                      
				                                        
				if ($cname eq 'tig' and not @langSet) {                  #
					
					#unless (@langSet) {
						my $new = XML::Twig::Elt->new('langSet');
						$new->paste(first_child=>$section);
						store($new);
						$child->move($new);
						push @children,$new;
						#}
					
				} 
				
				#at this point, the item is either langSet, transacGrp or descripGrp
				#or it is a tig but langset exists
				
				else
				
				{
					
					#does a simple search to find the nearest related element 
					#which could take this information.
					
					my $target;
					
					my @options=($child);
					do 
					
					{
						
						$target = shift @options;
						push @options, $target->parent();
						push @options, $target->siblings();
						push @options, $target->children();
						
					}
					
					until ((grep{$cname eq $_} @{$comp{$target->name()}}));
					
					$child->move($target);
					
				}
				
			}			
			
		}
		
		push @children, $child->children();
		
	}
	
	#tidy termEntry
	
	@children = $section->children();
	
	while ($child = shift @children) {
			
		my $cname = $child->name();
		
		#for the time being, we will just handle things on
		#a case by case basis.
		
		#descrip level, to be handled in addition to the exclusive cases below
		
		if ($cname eq 'descrip') {
			
			my $type = $child->att('type');
			
			if (grep{$type eq $_} keys %levels) {
				
				#move descrip with its parent
				
				my $head = $child->parent()->name() eq 'descripGrp' ? $child->parent() : $child;
				
				my $pname = $head->parent()->name();
				
				unless (grep{$pname eq $_} @{$levels{$type}}) {
					print $pname,"\n";
					print $type,"\n";
					if ($head->parent()->parent()->name() eq $levels{$type}[0]) {
						$head->move(first_child=>$head->parent()->parent());
					} #not sure why this isn't getting removed down below...
					
				}
				
			}
			
		}
		
		#a large list of exclusive cases
		
		if ($cname eq 'descripGrp') {
			
			#erase() leaves children in their parent's place.
			#any orphaned admin element raise a level.
			push @children,$child->children();
			$child->erase() unless $child->has_child('descrip');
			
		} elsif ($cname eq 'admin')
		
		#the following code bracket is a hacky fix 
		#to the hacky way I am enforcing constraints right now
		
		{
			my $type = $child->att('type');
			my $pname = $child->parent()->name();
			unless ('customerSubset projectSubset source'=~/$type/) {
				if (grep {$concomp{$type} eq $_} @{$comp{$pname}}) {
#					print $type,' ',$concomp{$type},' ',$pname,"\n";
					$child->set_name($concomp{$type});
					$cname=$concomp{$type};
					push @children, $child->parent();
				}
				else
				{
					if ($pname eq 'descripGrp') 
					
					{
						
						my $elt =
						XML::Twig::Elt->new
						(descrip=>
						{type=>'context'}=>
						$child->att('type').":".$child->text);
						
						$elt->replace($child);
					}
					
					else
					
					{
						
						my $elt =
						XML::Twig::Elt->new
						(note=>$child->att('type').":".$child->text);
						
						$elt->replace($child);
					}
					
				}
				
			}
			
		}
		
		elsif ($cname eq 'tig')
		
		{
			
			$child->move(last_child=>$child->parent());
			
			$child->
				sort_children( 
				sub {#print $_[0]->name(),"\n";
					return 2 if $_[0]->name() eq 'term';
				return 1 if $_[0]->name() eq 'termNote'}, 
				type => 'numeric', order => 'reverse');
			
			
		}
		
		elsif ($cname eq 'langSet') {
			
			$child->move(last_child=>$child->parent());
			#my $lang = defined $child->att('xml:lang') ? $child->att('xml:lang') : "EN";
			my $lang =$child->att('xml:lang');
#			print $lang,"\n";
			if ($lang ne lc $lang) {
			#if (undef $child->att('xml:lang') or $lang ne lc $lang) {
			
				$child->set_att('xml:lang'=>lc $lang);
			}
			
		}
		
		elsif ($cname eq 'trasnacGrp') 
		
		{
			$child->
				sort_children( 
				sub {return 1 if $_[0]->name() eq 'transac'}, 
				type => 'numeric', order => 'reverse');
		}
		
		elsif ($cname eq 'xref') {
			#print "xref\n";
			unless ($child->att('target'))
			
			{
				$child->set_att(target => $child->text());
			}
		}
		
		#this one is just hard coded for now
		
		elsif ($cname eq 'transac') {
			#cheap perl 'in' clone, has its issues
			my $text = $child->text();
			unless ('origination modification' =~ /$text/) {
				#print similarity ($text,'origination'),' ',similarity ($text,'modification'),'\n';
				$child->set_text(
				similarity ($text,'origination')>=similarity ($text,'modification') ?
				'origination':'modification');
			}
		}
		
		elsif ($cname eq 'termNote') {
			my $type = $child->att('type');
			if (' administrativeStatus grammaticalGender partOfSpeech termType ' =~ / $type /) {
				
				my $text = $child->text();
				#print "$type $text hi ";
				unless (grep{$text eq $_} @{$picklist{$type}}) {
				
					#store the invalid value in a note, which also can go in a tig
					my $note_text = 'original '.$type.':'.$text;
					my $elt = XML::Twig::Elt->new('note'=>$note_text);
					$elt->paste(last_child => $child->parent());
					
					my %relevance = map {$_ => similarity $text,$_} @{$picklist{$type}};
	
					my @j = (reverse sort {$relevance{$a} <=> $relevance{$b}} keys %relevance);
	
					my $guess = $j[0];
					
					#if ($relevance{$guess}>$tolerance) {
					#	$child->set_text($guess);
					#} else {
					#	$child->set_text($guess);
					#}
					if ('grammaticalGender partOfSpeech' =~ /$type/ and $relevance{$guess}<$tolerance) {
						$child->set_text('other');
					} else {
						$child->set_text($guess);
					}
					
				}
				
				#print "\n";
			}
		}
		
		push @children, $child->children();
	
		
			
	}	
	
	$section->print($tft);
	wipe();
	$section->delete();
	return 1;
	
}

sub name_check {
	my ($t,$section) = @_;
	#check names
	
	#stores element name for validity
	#attempts to fix name if no such
	#element exists in the TBX basic format.
	
	my $cname = $section->name();
	
	#stores parent name, parent of the root is set to 0
	
	my $pname = $section->level()>0 ? $section->parent()->name() : 0;
	
	#this is used to ensure that proper data categories are in the right kind of element
	
	
	if (my $ntype = constraint($section)) 
	
	{ 			
#		print "|"x10,$concomp{$ntype}," ",$ntype,"\n";
		$section->set_att(type=>$ntype);
		$section->set_name($concomp{$ntype});
		$cname = $concomp{$ntype};
		#$section->set_name($xcsname) if $cname ne $xcsname;
		
	}
	
	
	if (grep {$cname eq $_} @{$comp{$pname}}) {
		
		#stores the item in the correct variable if valid and not duplicate
		
		if (store($section)) {
			
			return "valid";
			
		}
		
	}
##	print "7"x7,$cname,"\n";
	my %relevance = map {$_ => similarity $cname,$_} keys %refs;
	
	my @j = (reverse sort {$relevance{$a} <=> $relevance{$b}} keys %relevance);
	
	foreach my $guess (@j) {
		
		#check if guess is worth listening to
		#print $guess.' '.$relevance{$guess}.' ';
		if ($relevance{$guess}>$tolerance) {
			
			$section->set_name($guess);
			
			#attempts to store, skips if a unique element is repeated
			
			if (store($section)) {
				
				return $guess;
				
			}
			
		}
		
	}
	
	#if the guess was not able to be stored, revert name to original 
	
	$section->set_name($cname);
	
	#return failure flag to caller
	
	return 0;
	
}

sub handle_aux {
	
	my ($t,$section) = @_;
	
	#calls name_check with backup code if no valid name can be assigned
	
	unless (name_check(@_)) {
		
		#create id to preserve original name
		
		#if there is an id tag, which is allowed by most elements
		my $id = $section->att("id") ? 
		
		#then keep it and append the old name in parentheses
		$section->att("id")." (".$section->name().")" :
		
		#otherwise, just set the id to the original name
		$section->name();
		$section->set_att("id"=>$id);
		
		#for aux items, make sourceDesc, which is made for this kind of info
		$section->set_name("sourceDesc");
		
		#store it. will not fail because sourceDesc is stackable
		store($section);
	}
	
	foreach my $m ($section->att_names()) {
		
		unless (grep {$m eq $_} @{$atts{$section->name()}}) {
			
			my $value = $section->att($m);
			my $temp = XML::Twig::Elt->new('p'=>$m.":".$value);
			#$temp->set_att("id"=>$m);
			$temp->paste(last_child=>$section);
			store($temp);
			$section->del_att($m);
		}
	}
	
	return 1;
	
}

sub location_control {
	
	#don't forget to name and att check root
	handle_aux(@_);
	
	my ($t,$section) = @_;
	
	#insert a brand mark
	if ($version>=1) {
		my $signature=XML::Twig::Elt->new('sourceDesc');
		my $signature_p=XML::Twig::Elt->new(
			'p'=>"Processed by Steamroller V.$version from $ARGV[0]."
		);

		#pastes this to the root, it will be sorted eventually
		$signature_p->paste($signature);
		$signature->paste($section);
		store($signature);
		
	}
	
	#insert a placeholder
	push $comp{'body'}, 'placeholder';
	$placeholder=XML::Twig::Elt->new('placeholder');
	
	#pastes to root, sorted in a second anyway.
	$placeholder->paste($section);
	
	#checks location and identity of root, which must be martif
	#checks name and identity of root.
	my $root_name = $section->name();
	
	#spotcheck for tbxm files with root tbx
	if ($root_name eq "tbx") {
		$section->set_name("martif");
		$martif = $section;
	} 
	
	#
	if ($root_name ne "martif") {
		
		#retrieves martif if deep in doc, otherwise makes one
		if (defined $martif) {
			
			$martif->cut();
			
		} else {
			
			$martif = XML::Twig::Elt->new('martif');
			
		}
		
		#roots martif, reorders.
		$section->cut();
		$t->set_root($martif);
		$section->paste($martif);
		$section=$martif;
		
	}
	
	#checks and fixes location of all children
	my @children = $section->children();
	my $child;
	
	while ($child = shift @children) {
		
		my $cname = $child->name();
		
		if ($cname eq "termEntry") {
			
			handle_term($t,$child);
			
			next;
			
		}

		my $pname = $child->parent()->name();
		
		my ($dest,$new);
		
		#checks to see if the element is in the right place
		
		unless (grep{$cname eq $_} @{$comp{$pname}}) {
			
			#package PCDATA in p element.
			
			if ($cname eq "#PCDATA") {
				
				my $new = XML::Twig::Elt->new('p');
			
				$new->paste(last_child => $child->parent());
			
				#puts the new element on the stack for further processing
			
				$child->cut();
				$child->paste($new);
				push @children,$child,$new;
				
			}
			
			elsif ($cname eq "p") {
				if ($pname eq 'revisionDesc') {
					$child->set_name('change');
				} 
			
				elsif ($pname eq 'titleStmt') {
					$child->set_name('note');
				} 
			
				#if the p is not in a valid element or already handled,
				#it must be in fileDesc or above.  The next blocks of code 
				#construct appropriate parents and move p to fit.
			
				elsif ($pname eq 'fileDesc') {
					my $new = XML::Twig::Elt->new('sourceDesc');
				
					$new->paste(last_child => $child->parent());
					store($new);
					$child->move($new);
				} 
			
				elsif ($pname eq 'martifHeader') {
									
					if (defined $fileDesc) {
					
						$child->move($fileDesc);
						
						push @children,$child;
						
					} else {
						
						$new = XML::Twig::Elt->new('fileDesc');
						$new->paste(first_child=>$martifHeader);
						store($new);
						$child->move($new);
						push @children,$child,$new;
					}
					
				} 
			
				#if the p is in the martif, put it in the martifHeader,
				#process it again, it is moved down step by step.
			
				elsif ($pname eq 'martif') {
					
					if (defined $martifHeader) {
						$child->move($martifHeader);
						push @children,$child;
					} else {
						$new = XML::Twig::Elt->new('martifHeader');
						$new->paste(first_child=>$martif);
						store($new);
						$child->move($new);
						push @children,$child,$new;
					}
				} 
			
				#in unhandled cases, move p upwards!
			
				else {
					
					$child->move($child->parent()->parent());
					push @children,$child;
				}
				
				store($child);
			}
			
			else {
				
				$dest = $renp{$cname};

				#check for proper parent and move there
				
				if (ref($dest) eq 'ARRAY') {
					$new = XML::Twig::Elt->new('termEntry');
					$child->move(first_child=>$new);
					handle_term($t,$new);
					next; 
					
					#this takes advantage of the fact that only termEntry
					#elements have arrays in the renp hash.  #a later 
					#steamroller needs to overhaul this whole system
				}
				
				elsif (defined ${$refs{$dest}}) {
					$child->cut();
					$child->paste(last_child => ${$refs{$dest}});
					
				} 
				
				#create proper parent and stuff it in the martif
				#then put it back on the stack; it will be processed
				#in turn and moved to the correct place.
				
				else {
#					
					
					$new = XML::Twig::Elt->new($dest);
					store($new);
					$new->paste(last_child=>$martif);
					push @children,$new;
					$child->move(last_child => $new);
					
				}
				
			}
			
			push @children, $child->children() if ($child->name() ne "text"); 
			
		}
		
		push @children, $child->children() if ($child->name() ne "text");
		
	}
	
	unless 
	($section->first_descendant(
	sub {return 1 if $_[0]->att('type') and $_[0]->att('type') eq 'XCSURI'}
	)) 
	
	#unless the XCSURI is defined, we will define it.
	
	{
		#my $elt= XML::Twig::Elt->new(encodingDesc => { p => 'TBXBasicXCSV02.xcs' });
		#$elt->paste($martifHeader);
		if (defined $encodingDesc) 
		
		{
			my $elt = XML::Twig::Elt->new(p=>{type=>'XCSURI'});
			$elt->paste($encodingDesc);
		}
		
		else
		
		{
			$encodingDesc=XML::Twig::Elt->new('encodingDesc');
			$encodingDesc->paste($martifHeader);
			my $elt = XML::Twig::Elt->new(p=>{type=>'XCSURI'},'TBXBasicXCSV02.xcs');
			$elt->paste($encodingDesc);
		}
		
	}
	
	#foreach my $c (keys %comp) {
	foreach my $c (@aux_items) {
		#condition to filter out elements with single children, and ignore undefined
		#also ignores the body since all termEntry have been removed
		
		if ($#{$comp{$c}}>0 and $c ne 'body') {
		
			foreach my $j (@{$comp{$c}}) {
			
				my $ref = $refs{$j};
			
				#in order listed in comp, which is preferred order,
				#put the element last——resulting in the correct order.
			
				if (ref($ref) eq 'REF') {
#					print "Pasting " . ${$ref}->name();
					${$ref}->move(last_child=>${$ref}->parent());
				} elsif (ref($ref) eq 'ARRAY') {
					foreach my $x (@{$ref}) {
						
						$x->move(last_child=>$x->parent());
		
					}
				} 
			}
		}
	}	
	
	
	
	return 1;
	
}

#receive file from command line

my $file = $ARGV[0];

#filter out non-tbx files

$file or die "Please provide a file!";

#TBX Steamroller accepts TBX, TBX-Min, TBX-Basic, or any XML file
#(Malformed TBX often bears the .xml filetype)

unless ($file =~ m/(tbx|xml|tbxm)\Z/ && -e $file) {
	die $file . " is not recognized xml!";
}

#constructs the TWIG

my $twig = XML::Twig->new(
	
pretty_print => 'indented',

twig_handlers => {
	
	output_html_doctype => 1,
	
	#Handles termEntry whole, including children
	termEntry => \&handle_term,
	
	#ignores children of termEntry, preventing double parsing 
	"termEntry//*" => sub {return 1;},
	
	#handles all elements.
	_default_ => \&handle_aux,
	
	#calls on root
	"/*" => \&location_control,
	
}
	
);

$twig->set_id_seed('c');

$twig->parsefile($file);

#steamroller should leave things alone unless they are wrong

unless ($twig->doctype()=~/TBXBasiccoreStructV02/) 

{
	
	$twig->set_doctype('martif',"TBXBasiccoreStructV02.dtd");
	
}



#stores the non-termEntry data to a string; this is very short compared to termEntry data.
my $auxilliary = $twig->sprint();

#close the auxilliary file and open for reading
close($tft);
open($tft,'<','temp_file_text.txt');

#open final output file
open(my $out,">",'result.tbx');
###print $out '<!DOCTYPE martif SYSTEM "TBXBasiccoreStructV02.dtd">'."\n";
#finds a placeholder which marks the proper location of the termEntry, inserts all termEntry
foreach my $line (split(/\n/,$auxilliary)) {
	if ($line =~ /      <placeholder/) {
		while (<$tft>) {
			print $out "$_" if ($_ ne "\n");
		}
		
	}
	
	else {
		print $out $line;
	}
	print $out "\n";
}

#plays console bell, useful for debugging; this program runs for a while on gigabyte+ files.
print "\a"x3;