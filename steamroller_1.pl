use warnings;
use strict;

#XML::Twig provides the core XML editing functionality to Steamroller
use XML::Twig;

#Similarity compares two strings to see how similar they are
#This is used to guess what an invalid element should be called (conceptEntry_Entry -> conceptEntry)
use String::Similarity;

#Used with Similarity to put a lower bound on guess validity.
#A lower tolerance can catch more matches but may make bad guesses.
my $tolerance = 0.4;

#if $version is greater than 1, the steamroller will delete temporary files
#and add a brand marker to identify the file as a steamroller-generated file.
my $version = 1.01;

my $file;
#opens temporary file to store conceptEntry elements
open (my $tft,'>','temp_file_text.txt'); 

#opens logfile
open (my $log,'>','steamroller_log.txt');

#initialize variables which store elements as they are encountered, used later for rearrangement
my(
$tbx,
$tbxHeader,
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
@refObjectSec,
@refObject,
@item,
$placeholder,
@conceptEntry,
@langSec,
@termSec,
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
@sc,
@ec,
@ph,
);

#hash of element names to the reference for their corresponding variable
my %refs=(
'tbx' => \$tbx,
'tbxHeader' => \$tbxHeader,
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
'refObjectSec' => \@refObjectSec,
'refObject' => \@refObject,
'item' => \@item,
'placeholder' => \$placeholder,
'conceptEntry' => \@conceptEntry,
'langSec' => \@langSec,
'termSec' => \@termSec,
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
'sc' => \@sc,
'ec' => \@ec,
'ph' => \@ph,
);

#hash of element compatibility, mapped parent to child
my %comp=(
0 => ['tbx'],
'tbx' => ['tbxHeader','text'],
'tbxHeader' => ['fileDesc','encodingDesc','revisionDesc'],
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
'body' => ['conceptEntry'],
'back' => ['refObjectSec'],
'refObjectSec' => ['refObject'],
'refObject' => ['item'],
'item' => ['#PCDATA','hi','foreign','sc','ec','ph'],
'conceptEntry' => [qw(langSec descrip descripGrp admin transacGrp note ref xref)],
'langSec' => [qw(termSec descrip descripGrp admin transacGrp note ref xref)],
'termSec' => [qw(term termNote descrip descripGrp admin transacGrp note ref xref)],
'term' => ["#PCDATA", qw(hi)],
'termNote' => ["#PCDATA", qw(hi foreign sc ec ph)],
'descrip' => ["#PCDATA", qw(hi foreign sc ec ph)],
'descripGrp' => [qw(descrip admin)],
'admin' => ["#PCDATA", qw(hi foreign sc ec ph)],
'transacGrp' => [qw(transac transacNote date)],
'note' => ["#PCDATA", qw(hi foreign sc ec ph)],
'ref' => ["#PCDATA"],
'xref' => ["#PCDATA"],
'transac' => ["#PCDATA", qw(hi foreign sc ec ph)],
'transacNote' => ["#PCDATA", qw(hi foreign sc ec ph)],
'date' => ["#PCDATA"],
'hi' => ["#PCDATA"],
'foreign' => ["#PCDATA", qw(hi foreign sc ec ph)],
'sc' => ["#PCDATA"],
'ec' => ["#PCDATA"],
'ph' => ["#PCDATA"],
);

#a list of elements which do not occur in a conceptEntry
my @aux_items=(
'tbx' ,
'tbxHeader' ,
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
'refObjectSec' ,
'refObject' ,
); 

#hash of element compatibiity, child to possible parents
my %renp=(
'tbxHeader'    => 'tbx',
'text'            => 'tbx',
'fileDesc'        => 'tbxHeader',
'encodingDesc'    => 'tbxHeader',
'revisionDesc'    => 'tbxHeader',
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
'conceptEntry'       => 'body',
'placeholder'     => 'body',
'refObjectSec'   => 'back',
'refObject'       => 'refObjectSec',
'item'            => 'refObject',
'conceptEntry' 	  => [qw()],
'langSec' 		  => [qw(conceptEntry)],
'termSec' 			  => [qw(langSec)],
'term' 			  => [qw(termSec)],
'termNote' 		  => [qw(termSec)],
'descrip' 		  => [qw(conceptEntry langSec termSec descripGrp)],
'descripGrp' 	  => [qw(conceptEntry langSec termSec)],
'admin' 		  => [qw(conceptEntry langSec termSec descripGrp)],
'transacGrp' 	  => [qw(conceptEntry langSec termSec)],
'note' 			  => [qw(conceptEntry langSec termSec)],
'ref' 			  => [qw(conceptEntry langSec termSec)],
'xref' 			  => [qw(conceptEntry langSec termSec)],
'transac' 		  => [qw(conceptEntry langSec termSec transacGrp)],
'transacNote' 	  => [qw(transacGrp)],
'date' 			  => [qw(transacGrp)],
'hi' 			  => [qw(term termNote descrip admin note transac transacNote foreign)],
'foreign' 		  => [qw(termNote descrip admin note transac transacNote foreign)],
'sc' 			  => [qw(termNote descrip admin note transac transacNote foreign)],
'ec' 			  => [qw(termNote descrip admin note transac transacNote foreign)],
'ph' 			  => [qw(termNote descrip admin note transac transacNote foreign)],
'#PCDATA' 		  => [qw(term termNote descrip admin note ref
					xref transac transacNotedate hi foreign sc ec ph)],
);

#hash of all allowed attributes by element
my %atts=(
'tbx' 		  => ['type','xml:lang'],
'tbxHeader' 	  => ["id"],
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
'refObjectSec'   => ["id",'type'],
'refObject' 	  => ["id"],
'item' 			  => ["id",'type'],
'concecEntry' 	  => [qw(id)],
'langSec' 		  => [qw(id xml:lang)],
'termSec' 			  => [qw(id)],
'term' 			  => [qw(id)],
'termNote' 		  => [qw(id xml:lang type target datatype)],
'descrip' 		  => [qw(id xml:lang type target datatype)],
'descripGrp' 	  => [qw(id)],
'admin' 		  => [qw(id xml:lang type target datatype)],
'transacGrp' 	  => [qw(id)],
'note' 			  => [qw(id xml:lang)],
'ref' 			  => [qw(id xml:lang type target datatype)],
'xref' 			  => [qw(id target type)],
'transac' 		  => [qw(id xml:lang type target datatype)],
'transacNote' 	  => [qw(id xml:lang type target datatype)],
'date' 			  => [qw(id)],
'hi' 			  => [qw(type target xml:lang)],
'foreign' 		  => [qw(id xml:lang)],
'sc' 			  => [qw(i type)],
'ec' 			  => [qw(i)],
'ph' 			  => [qw(type)],
'#PCDATA' 		  => [qw()],
);

#a hash used in processing terms, which indicates
#the type of PCDATA acceptable in various elements.
my %pcstorage = (
'conceptEntry'=>'note',#best choice?
'langSec'=>'note',
'termSec'=>'note',
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
'sc' 		=>0,
'ec' 		=>0,
'ph' 		=>0,
'#PCDATA' 	=>0,
'p'			=>0,
);

#stores an ELT object into a variable referenced the %refs hash above.
#Used to check duplication of unique elements, various other uses.
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

#clears variables used in processing conceptEntry elements
#so that large files don't leak memory
sub wipe {
	#cuts memory usage to a 1/3 of otherwise... not terrible
	@note = ();
	@conceptEntry = ();
	@langSec = ();
	@termSec = ();
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
	@sc = ();
	@ec = ();
	@ph = ();
}

#maps data categories to the element they occur in.
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
'respPerson'				=> 'refObjectSec',
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
'bold'						=> 'sc',	   # = Bold                      
'ulined'					=> 'sc',     # = Underline              
'dulined'					=> 'sc',     # = Double-underlined      
'color'						=> 'sc',     # = Color change           
'struct'					=> 'sc',     # = XML/SGML structure
'italic'					=> 'sc',     # = Italic
'scap'						=> 'sc',     # = Small caps
'font'						=> 'sc',     # = Font change
'link'						=> 'sc',     # = Linked text
'index'						=> 'ph',	   # = Index marker          these are text     
'time'						=> 'ph',      # = Time                  markup tags
'enote'						=> 'ph',      # = End-note                 
'image'						=> 'ph',      # = Image                    
'lb'						=> 'ph',      # = Line break               
'inset'						=> 'ph',      # = Inset                        
'date'						=> 'ph',      # = Date
'fnote'						=> 'ph',      # = Footnote
'alt'						=> 'ph',      # = Alternate text
'pb'						=> 'ph',      # = Page break			sc ph types inhereted from
);									   # http://www.ttt.org/oscarstandards/tmx/tmxnotes.htm

#allowed picklist values for the listed constraints
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
'context'=>['termSec'],
'definition'=>['langSec','conceptEntry'],
'subjectField'=>['conceptEntry'],
);

#Makes sure that data category types occur in the right elements, per XCS
sub constraint {
	
	#takes one argument, an element
	my ($section) = @_;
	
	if (my $type = $section->att('type')) 
	#only trigger if element has 'type' attribute, indicating DCA data
	{
		
		#ignore the tbx
		return 0 if ($section->name() eq 'tbx');
		
		if (grep {$type eq $_} keys %concomp) 
		#Trigger if the type is one of the allowed types
		{
			
			if ($concomp{$type} eq $section->name()) 
			#Exit if the valid type is in the right element
			{
				return 0;
			}
			
			#If the type was valid by the element mismatched,
			#return the correct element name
			return $type;
			
			
		} 
		
		#the type is not valid; guess closest possible type; see name_check
		
		my %relevance = map {$_ => similarity $type,$_} keys %concomp;
	
		my @j = (reverse sort {$relevance{$a} <=> $relevance{$b}} keys %relevance);
	
		foreach my $guess (@j) {
	
			if ($relevance{$guess}>$tolerance) {
				
				return $guess;
			
			}
		
		}
		
	}
	
	else 
	#Exit if not DCA element
	{
		
		return 0;
		
	}
}

#processes a termElement, wherever encountered.
sub handle_term {
	
	my ($t,$section) = @_;
	
	####
	my $line = $t->current_line();
	
	#add generic incrementing id tag
	unless ($section->att('id')) {
		$section->add_id();
		printf $log "conceptEntry ending in $line lacks id, setting id to '%s'.\n",
		$section->att('id'); 
	};
	my $tid = "conceptEntry ".$section->att('id')." ending in line $line";
	
	#check attributes of conceptEntry
	foreach my $m ($section->att_names()) {
		
		unless (grep {$m eq $_} @{$atts{$section->name()}}) {
			
			print $log "Attribute $m invalid for conceptEntry, storing as a note for $tid .\n";
			
			#stores any invalid attributes as a note in conceptEntry
			my $value = $section->att($m);
			my $temp = XML::Twig::Elt->new('note'=>$m."::".$value); #added second colon for distinction
			$temp->paste(last_child=>$section);
			store($temp);
			$section->del_att($m);
		}
	}
	
	#perform name and attribute check for all children of the conceptEntry

	my @children = $section->children();
	my $child;
	
	#name check for each child
	while ($child = shift @children) 
	#takes from stack one at a time; it is repopulated during loop
	{
		
		unless (name_check($t,$child,$tid)) 
		#triggers if name_check fails to validate or correct name, returning 0;
		{
			
			#creates a dummy note containing the invalid name
			#dumps it and the invalid elements children in place
			
			
			
			my $cname=$child->name();
			print $log "Element $cname has invalid tag. Storing as note, $tid.\n";
			my $temp = XML::Twig::Elt->new(note => $cname);
			$temp->paste(last_child => $child);
			$child->erase(); 
		
			#stores it, will not fail because note is stackable
			store($section);
			
		}

		foreach my $m ($child->att_names()) 
		#checks each attribute of the current child
		{
			
			unless (grep {$m eq $_} @{$atts{$child->name()}}) 
			#triggers if the attribute is not listed as valid for this element
			{
				print $log "Attribute $m is invalid for ".$child->name().".  Storing as note, $tid.\n";
				#lazily creates a p element containing attribute, gets renamed later
				my $value = $child->att($m);
				my $temp = XML::Twig::Elt->new('p'=>$value);
				$temp->set_att("id"=>$m);
				$temp->paste(last_child=>$child);
				store($temp);
				$child->del_att($m);
			}
		}
		
		#feeds children of element to back of stack to ensure full coverage
		push @children, $child->children() if ($child->name() ne "text");
		
	}	 
	
	#reorders the elements of the conceptEntry
	@children = $section->children();
	
	while ($child = shift @children) 
	#various instances of push @children... repopulate the stack
	{
		
		#stores name of child and parent for convenience
		my $cname = $child->name();
		my $pname = $child->parent()->name();
		
		unless (grep{$cname eq $_} @{$comp{$pname}}) 

		#triggers for elements inside wrong parent
		{
			
			if ($cname eq "#PCDATA") 
			#if PCDATA is in an element which can't take PCDATA
			{
				
				my $temp = XML::Twig::Elt->new('p'=>$child->text());
				$temp->replace($child);
				
				push @children,$temp;
				
			}
			
			elsif (not $pcstorage{$cname}) 
			#if element is a PCDATA holder but misplaced
			#causes some problems fixed in the 'tidy' section below...
			{
				
				my $fate = $pcstorage{$pname};
				
				if (not $fate or $cname eq 'xref') 
				#the current parent cannot have element children
				#or it contains important data?
				#including xref here is a temporary fix
				{
					####
					print $log "Moving $cname up to ".$child->parent()->parent()->name().
					" in $tid.\n";
					
					#simple move the element up and try again
					$child->move(last_child=>$child->parent()->parent());
					
					#return to the list
					push @children,$child;
					
				}
				
				else
				#the parent can have an element which bears PCDATA, just not this one
				{
					
					printf $log "Renaming element '%s' with text '%s' to $fate in $tid.\n",$child->name(),$child->text();
					
					#rename it to be something that works
					
					$child->set_name($fate);
					
					if ($fate eq "note")
					{
						printf $log "Storing invalid attributes from <note> with text '%s' in $tid.\n", $child->text(); #caleb106 - Store the attribute before they are removed
						my @attNames = $child->att_names;
						
						foreach my $att ($child->att_names)
						{
							if ($atts{'note'} !~ $att)
							{
								$child->set_text($child->att($att)."::".$child->text); #caleb106 Store attribute in note value before deleting
                                $child->del_att($att);
							}
						}
						
					}
					
					#This code mistakenly mislables DCA data
					#In current version, these problems are fixed in 'tidy' section'
					
				}
				
			}               
			                                            
			else 
			#triggers for all other conceptEntry children
			{                                      
				                                        
				if ($cname eq 'termSec' and not @langSec) 
				#puts orphaned termSec in new langSec if no langSec exists
				{                  
					
					####
					print $log "Creating langSec element for termSec in $tid";
					#($child->first_child('term'))
					my $new = XML::Twig::Elt->new('langSec');
					$new->paste(first_child=>$section);
					store($new);
					$child->move($new);
					push @children,$new;
					
				} 
				
				else
				#at this point, the item is either langSec, transacGrp or descripGrp
				#or it is a termSec but langSec exists
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
					
					print $log "Moving $cname to ".$target->name()."in $tid\n";
					$child->move($target);
					
				}
				
			}			
			
		}
		
		push @children, $child->children();
		
	}
	
	#tidy conceptEntry
	@children = $section->children();
	
	while ($child = shift @children) 
	#cycles through all children of conceptEntry again to double-check validity
	{
			
		my $cname = $child->name();
		
		#for the time being, we will just handle things on
		#a case by case basis.
		
		#makes sure DCA in a descrip element is at correct level
		if ($cname eq 'descrip') {
			
			my $type = $child->att('type');
			
			if (grep{$type eq $_} keys %levels) {
				
				#moves relative to $head, which is either the 
				#descrip or the descripGrp it may be in
				my $head = 
				$child->parent()->name() eq 'descripGrp' ?
				$child->parent() : $child;
				
				my $pname = $head->parent()->name();
				
				unless (grep{$pname eq $_} @{$levels{$type}}) 
				#unless the parent is the correct parent for this data type
				{

					if ($head->parent()->parent()->name() eq $levels{$type}[0]) 
					#move to the grandparent if that is the right place
					{
						print $log "Moving ".$head->name()." to "
						.$head->parent()->parent()->name()." in $tid\n";
						$head->move(first_child=>$head->parent()->parent());
					} 
					
				}
				
			}
			
		}
		
		#a large list of mutually exclusive cases
		
		if ($cname eq 'descripGrp') 
		#delete empty descripGrp or ones with only 'admin' elements
		{
			
			#erase() leaves children in their parent's place.
			#any orphaned admin element raise a level.
			push @children,$child->children();
			unless ($child->has_child('descrip')) {
				$child->erase();
				printf $log "descripGrp has no descrip, deleting element and advancing children in $tid.\n"; 
			}
			
		} elsif ($cname eq 'admin')
		
		#the following code bracket is a hacky fix 
		#to the hacky way I am enforcing constraints right now
		#previous code changes many DCA elements to 'admin' instead of moving them
		#so this has to...change them back, sort of. It works for now.
		{
			my $type = $child->att('type');
			my $pname = $child->parent()->name();
			unless ('customerSubset projectSubset source'=~/$type/) 
			#triggers if the data type is not right for an admin element
			{
				if (grep {$concomp{$type} eq $_} @{$comp{$pname}}) 
				#renames if the right element for that type fits in the parent
				{
					printf $log "Renaming DCA element with type '%s' to '%s' in $tid.\n",$type,$concomp{$type};
					$child->set_name($concomp{$type});
					$cname=$concomp{$type};
					push @children, $child->parent();
				}
				else
				#dumps the data in place in a valid form
				{
					if ($pname eq 'descripGrp') 
					#makes a context descrip in a descripGrp
					{
						
						my $elt =
						XML::Twig::Elt->new
						(descrip=>
						{type=>'context'}=>
						$child->att('type').":".$child->text);
						
						$elt->replace($child);
					}
					
					else
					#makes a note in any other element
					{
						
						my $elt =
						XML::Twig::Elt->new
						(note=>$child->att('type').":".$child->text);
						
						$elt->replace($child);
					}
					
				}
				
			}
			
		}
		
		elsif ($cname eq 'termSec')
		#puts termSec in right place and sorts children
		{
			print $log "Sorting termSec in $tid.\n";
			$child->move(last_child=>$child->parent());
			
			$child->
				sort_children( 
				sub {
					return 2 if $_[0]->name() eq 'term';
				return 1 if $_[0]->name() eq 'termNote'}, 
				type => 'numeric', order => 'reverse');
			
			
		}
		
		elsif ($cname eq 'langSec') 
		#makes lang lower case, probably unnecessary
		{
			print $log "Reordering langSec in $tid.\n";
			$child->move(last_child=>$child->parent());
			
			my $lang =$child->att('xml:lang');

			if ($lang ne lc $lang) {
			
				$child->set_att('xml:lang'=>lc $lang);
			
			}
			
		}
		
		elsif ($cname eq 'trasnacGrp') 
		#sorts children of transancGrp
		{
			$child->
				sort_children( 
				sub {return 1 if $_[0]->name() eq 'transac'}, 
				type => 'numeric', order => 'reverse');
		}
		
		elsif ($cname eq 'xref') 
		#makes a temporary target, not finalized
		{
			
			unless ($child->att('target'))
			
			{
				printf $log "Attribute 'target' missing from xref, set to '%s', please review, in $tid.\n", $child->text();
				$child->set_att(target => $child->text());
			}
		}
		
		elsif ($cname eq 'transac') 
		#makes sure the text of 'transac' is valid
		{
			
			my $text = $child->text();
			
			unless ('origination modification' =~ /$text/) {
				printf $log "transac spec must be origination or modification, '%s' not allowed. ",$child->text();
				$child->set_text(
				similarity ($text,'origination')>=similarity ($text,'modification') ?
				'origination':'modification');
				printf $log "Setting to '%s' in $tid.\n",$child->text();
			}
		}
		
		elsif ($cname eq 'termNote') {
			my $type = $child->att('type');
			
			#cheap perl clone of python 'in', it is safe because
			#the values of $type are limited to those allowed for termNote
			if (' administrativeStatus grammaticalGender partOfSpeech termType '
			 		=~ / $type /) 
					
			{
				
				my $text = $child->text();
				
				unless (grep{$text eq $_} @{$picklist{$type}}) {
				
					#store original invalid value in a note, also valid in termSec
					my $note_text = 'original '.$type.':'.$text;
					
					my $elt = XML::Twig::Elt->new('note'=>$note_text);
					$elt->paste(last_child => $child->parent());
					
					#replaces invalid value with closest match
					my %relevance = map {$_ => similarity $text,$_} @{$picklist{$type}};
	
					my @j = 
					(reverse sort {$relevance{$a} <=> $relevance{$b}} keys %relevance);
	
					my $guess = $j[0];

					if ('grammaticalGender partOfSpeech' =~ /$type/ and
					$relevance{$guess}<$tolerance) 
					#sets value as 'other' if possible and the match was poor
					{
						
						print $log "Value '$text' invalid for element ".$child->name().". ".
						"Storing as note, replacing with 'other', $tid.\n";
						
						$child->set_text('other');
					} 
					
					else 
					#otherwise forces closest match
					{
						print $log "Value '$text' invalid for element ".$child->name().". ".
						"Storing as note, replacing with '$guess', $tid.\n";
						
						$child->set_text($guess);
					}
					
				}
				
			}
			#does nothing if the type is something else, those have unrestricted values
		}
		
		elsif ($cname eq 'date') {
			
			unless ($child->text =~ /....-..-..$/) {
				#removes h-m-s timestamp from time, leaving only date
				printf $log "Date format is YYYY-MM-DD, '%s' not allowed, ",$child->text();
				
				$child->set_text(substr $child->text(),0,10);
				
				printf $log "changing to '%s' in $tid.\n",$child->text();
			}
			
		}
		
		push @children, $child->children();
	
		
			
	}	
	
	$section->print($tft);
	
	#calls routine to clear variables used and conserve memory
	wipe();
	$section->delete();
	
	return 1;
	
}

#checks name for auxilliary elements
sub name_check {
	
	#receive arguments from parser, tree and the element
	my ($t,$section,$line) = @_;
	
	#checks names for validity
	#attempts to fix name if no such
	#element exists in the TBX basic format.
	
	#stores element name 
	my $cname = $section->name();
	
	#stores parent name, parent of the root is set to 0
	my $pname = $section->level()>0 ? $section->parent()->name() : 0;
	
	#ensure that proper data categories are in the right kind of element
	if (my $ntype = constraint($section)) 
	#sets $ntype to proper element tag if given by constraint subroutine
	{ 			
		#currently lossy
		
		printf $log "Data category '%s' cannot go in element '%s'. Maybe for the attribute you meant '%s' in the tag '%s' in %s.\n",
		$section->att('type'),$section->name(),$ntype,$concomp{$ntype},$line;
		$section->set_att(type=>$ntype);
		#$section->set_name($concomp{$ntype});
        $section->set_name("note"); #caleb106 Set invalid element as note
		$cname = $concomp{$ntype};
		
	}
	
	if (grep {$cname eq $_} @{$comp{$pname}}) 
	#stores the item in the correct variable if valid
	{
		
		
		if (store($section)) 
		#returns to handle_aux if the element was accepted by store
		{
			
			return "valid";
			
		}
		
	}
	
	#the original closest match finder, cloned elsewhere in steamroller
	
	#creates hash of valid names by relevance to current name
	my %relevance = map {$_ => similarity $cname,$_} keys %refs;
	
	#makes list sorted by validity
	my @j = (reverse sort {$relevance{$a} <=> $relevance{$b}} keys %relevance);
	
	foreach my $guess (@j) 
	#goes through guesses from best to worst
	{
		
		if ($relevance{$guess}>$tolerance) 
		#returns only if close enough above tolerance level
		{
			
			$section->set_name($guess);
			
			if (store($section)) 
			#attempts to store, skips if a unique element is repeated
			{
		
				printf $log "Element %s has invalid name, renaming '%s' in $line.\n",
				$cname, $guess;
				return $guess;
				
			}
			
		}
		
	}
	
	#if the guess was not able to be stored, revert name to original 
	$section->set_name($cname);
	
	#return failure flag to caller
	return 0;
	
}

#called by parser on all elements outside conceptEntry
sub handle_aux {
	
	#receive arguments from parser, tree and the element
	my ($t,$section) = @_;
	
	####
	my $line= sprintf("element '%s' ending in line %d",$section->name(),$t->current_line());
	
	#calls name_check with backup code for if no valid name can be assigned
	unless (name_check(@_,$line)) {
		
		#create id to preserve original name
		printf $log "Storing unrecognized $line in sourceDesc.\n";
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
	
	#check attributes
	foreach my $m ($section->att_names()) {
		
		unless (grep {$m eq $_} @{$atts{$section->name()}}) 
		#if the attribute is not allowed, store it as a child to original
		{
			
			my $value = $section->att($m);
			my $temp = XML::Twig::Elt->new('p'=>$m.":".$value);
			
			print $log "Attribute $m is invalid for ".$section->name().".  Storing as a note.\n";
			
			$temp->paste(last_child=>$section);
			store($temp);
			$section->del_att($m);
		}
	}
	
	return 1;
	
}

# called on root to sort entire tree
sub location_control {
	
	#name and att check root
	handle_aux(@_);
	
	#receive arguments from parser, tree and the element
	my ($t,$section) = @_;
	
	#insert a brand mark
	if ($version>=1) {
		my $signature=XML::Twig::Elt->new('sourceDesc');
		my $signature_p=XML::Twig::Elt->new(
			'p'=>"Processed by Steamroller V.$version from $file."
		);

		#pastes this to the root, it will be sorted eventually
		$signature_p->paste($signature);
		$signature->paste($section);
		store($signature);
		
	}
	
	#insert a placeholder for termEntries
	#tells steamroller that placeholder belongs in 'body' element
	push @{ $comp{'body'} }, 'placeholder';
	$placeholder=XML::Twig::Elt->new('placeholder');
	
	#pastes to root, sorted in a second anyway.
	$placeholder->paste($section);
	
	#checks location and identity of root, which must be tbx
	#checks name and identity of root.
	my $root_name = $section->name();
	
	#spotcheck for tbxm files with root tbx #caleb106 No case needed for TBX v3
	#if ($root_name eq "tbx") {
	#	printf $log "root name 'tbx' invalid for TBX-Basic, changing to 'tbx.'\n";
	#	$section->set_name("tbx");
	#	$tbx = $section;
	#} 
	
	if ($root_name ne "tbx") 
	#if tbx is not root
	{
		
		
		if (defined $tbx) 
		#retrieves tbx if deep in doc
		{
			####
			print $log "Misplaced tbx, moving to root.\n";
			$tbx->cut();
			
		} 
		
		else 
		# otherwise makes one
		{
			
			####
			print $log "Missing tbx, creating and moving to root.\n";
			
			$tbx = XML::Twig::Elt->new('tbx');
			
		}
		
		#roots tbx, reorders.
		
		$section->cut();
		$t->set_root($tbx);
		$section->paste($tbx);
		$section=$tbx;
		
	}
	
	#change dialect name
	if ($section->att('type') ne "TBX-Basic")
	{
		print $log "Changing dialect type to 'TBX-Basic'.\n";
		$section->set_att('type' => 'TBX-Basic');
	}
	
	#checks and fixes location of all children
	my @children = $section->children();
	my $child;
	
	while ($child = shift @children) 
	#reads children one at a time from stack
	{
		
		my $cname = $child->name();
		
		if ($cname eq "conceptEntry") 
		#passes missed, misnamed or misplaced termEntries to handler
		{
			
			handle_term($t,$child);
			
			next;
			
		}

		my $pname = $child->parent()->name();
		
		my ($dest,$new);
		
		#checks to see if the element is in the right place
		
		unless (grep{$cname eq $_} @{$comp{$pname}})
		#if child cannot belong to its parent
		{
			
			
			
			if ($cname eq "#PCDATA") 
			#if PCDATA is out of place, package in p element
			{
				
				my $new = XML::Twig::Elt->new('p');
			
				$new->paste(last_child => $child->parent());
			
				#puts the new element on the stack for further processing
				print $log "Moving data ".$child->text()." into p element.\n";
				$child->cut();
				$child->paste($new);
				push @children,$child,$new;
				
			}
			
			elsif ($cname eq "p") 
			#appropriately rename p element within certain elements
			{
				if ($pname eq 'revisionDesc') {
					printf $log "Element p cannot exist in revisionDesc, changing to 'change'. \n";
					$child->set_name('change');
				} 
			
				elsif ($pname eq 'titleStmt') {
					printf $log "Element p cannot exist in titleStmt, changing to 'note'. \n";
					$child->set_name('note');
				} 
			
				#if the p is not in a valid element or already handled,
				#it must be in fileDesc or above.  The next blocks of code 
				#construct appropriate parents and move p to fit.
			
				elsif ($pname eq 'fileDesc') 
				#create a scourceDesc for it if in fileDesc
				{
					my $new = XML::Twig::Elt->new('sourceDesc');
				
					$new->paste(last_child => $child->parent());
					store($new);
					
					print $log "Housing p with text '".$child->text().
					"' in new sourceDesc in fileDesc.\n";
					
					$child->move($new);
				} 
			
				elsif ($pname eq 'tbxHeader') 
				#move it to the fileDesc 
				{
									
					if (defined $fileDesc) 
					
					{
						print $log "Moving p with text '".$child->text().
						"' to fileDesc.\n";
						$child->move($fileDesc);
						#and process again on next past
						push @children,$child;
						
					} 
					
					else 
					#or make one if none exists
					{
						print $log "fileDesc missing.\n".
						"Moving p with text '".$child->text().
						"' to new fileDesc.\n";
						$new = XML::Twig::Elt->new('fileDesc');
						$new->paste(first_child=>$tbxHeader);
						store($new);
						$child->move($new);
						push @children,$child,$new;
					}
					
				} 
			
				#if the p is in the tbx, put it in the tbxHeader,
				#process it again, it is moved down step by step.
			
				elsif ($pname eq 'tbx') {
					
					if (defined $tbxHeader) {
						
						print $log "Moving p with text '".$child->text().
						"' to tbxHeader.\n";
						
						$child->move($tbxHeader);
						push @children,$child;
					} else {
						
						print $log "tbxHeader missing.\n".
						"Moving p with text '".$child->text().
						"' to new tbxHeader.\n";
						
						$new = XML::Twig::Elt->new('tbxHeader');
						$new->paste(first_child=>$tbx);
						store($new);
						$child->move($new);
						push @children,$child,$new;
					}
				} 
			
				else 
				#in unhandled cases, move p upwards!
				{
					print $log "Moving ".$child->name. " to ".
					$child->parent()->parent()->name()."\n";
					$child->move($child->parent()->parent());
					push @children,$child;
				}
				
				store($child);
			}
			
			else 
			#if element is not PCDATA or p element
			{
				#get valid parent from hash
				$dest = $renp{$cname};
				
				#check for proper parent and move there
				if (ref($dest) eq 'ARRAY') 
				#this takes advantage of the fact that only conceptEntry
				#elements have arrays in the renp hash.  #a later 
				#steamroller needs to overhaul this whole system
				{
					print $log "Moving $cname to a new conceptEntry.\n";
					#put into a new conceptEntry for storage
					$new = XML::Twig::Elt->new('conceptEntry');
					$child->move(first_child=>$new);
					handle_term($t,$new);
					next; 

				}
			
				elsif (defined ${$refs{$dest}}) 
				#puts in proper parent if it exists
				{
					####
					print $log "Moving element $cname to $dest\n";
					
					$child->cut();
					$child->paste(last_child => ${$refs{$dest}});
					
				} 
				
				else 
				#create proper parent and stuff it in the tbx
				#then put it back on the stack; it will be processed
				#in next pass and moved to the correct place.
				{					
					print $log "Moving $cname to new $dest.\n";
					$new = XML::Twig::Elt->new($dest);
					store($new);
					$new->paste(last_child=>$tbx);
					push @children,$new;
					$child->move(last_child => $new);
					
				}
				
			}
			
		}
		
		push @children, $child->children() if ($child->name() ne "text");
		
	}
	
	unless 
	($section->first_descendant(
	sub {return 1 if $_[0]->att('type') and $_[0]->att('type') eq 'XCSURI'}
	)) 
	
	#unless the XCSURI is defined, we will define it.
	
	{
		print $log "Setting XCSURI to TBXBASICXCSV02.xcs\n";
		if (defined $encodingDesc) 
		#put in existing encodingDesc
		{
			my $elt = XML::Twig::Elt->new(p=>{type=>'XCSURI'},'TBXBasicXCSV02.xcs');
			$elt->paste($encodingDesc);
		}
		
		else
		#or make it
		{
			$encodingDesc=XML::Twig::Elt->new('encodingDesc');
			$encodingDesc->paste($tbxHeader);
			my $elt = XML::Twig::Elt->new(p=>{type=>'XCSURI'},'TBXBasicXCSV02.xcs');
			$elt->paste($encodingDesc);
		}
		
	}
	
	foreach my $c (@aux_items) 
	#condition to filter out elements with single children, and ignore undefined
	#also ignores the body since all conceptEntry have been removed
	{
		
		if ($#{$comp{$c}}>0 and $c ne 'body') {
		
			foreach my $j (@{$comp{$c}}) {
			
				my $ref = $refs{$j};
			
				#in order listed in comp, which is preferred order,
				#put the element last——resulting in the correct order.
			
				if (ref($ref) eq 'REF') 
				#reorder unique elements
				{					
					${$ref}->move(last_child=>${$ref}->parent());
				}
				
				elsif (ref($ref) eq 'ARRAY') 
				#reorder repeatable elements
				{
					foreach my $x (@{$ref}) {
						
						$x->move(last_child=>$x->parent());
		
					}
				} 
			}
		}
	}	
	#returning 1 is better for the parser
	return 1;
	
}

$file = $ARGV[0];
until ($file && $file =~ m/(tbx|xml|tbxm)\Z/ && -e $file) {
	print "Please enter a valid tbx file:\n";
	$file = <STDIN>;
	chomp $file;
}




#constructs the TWIG
my $twig = XML::Twig->new(
	
pretty_print => 'indented',

output_encoding =>'utf-8', #probably important

twig_handlers => {
	
	output_html_doctype => 1,
	
	#Handles conceptEntry whole, including children
	conceptEntry => \&handle_term,
	
	#ignores children of conceptEntry, preventing double parsing 
	"conceptEntry//*" => sub {return 1;},
	
	#handles all elements.
	_default_ => \&handle_aux,
	
	#calls on root
	"/*" => \&location_control,
	
}
	
);

$twig->set_id_seed('c');

$twig->parsefile($file);

#set correct doctype if it is wrong
#steamroller should leave things alone unless they are wrong
#unless ($twig->doctype()=~/TBXBasiccoreStructV02/) 

#{
#	printf $log "Setting doctype declaration to TBXBasiccoreStructV02.dtd.\n";
#	$twig->set_doctype('tbx',"TBXBasiccoreStructV02.dtd");
	
#}



#stores the parsed non-conceptEntry data to a string
my $auxilliary = $twig->sprint();

#fix a weird glitch with XML::Twig
$auxilliary =~ s/><!/>\n<!/g;

#close the conceptEntry file and open for reading
close($tft);
open($tft,'<','temp_file_text.txt');

#open final output file
my $out_name = $file;
$out_name =~ s/(.+?)\..+/$1_steamroller.tbx/;
$out_name = 'result.tbx' if $version<1;
open(my $out, ">:encoding(UTF-8)",$out_name);

foreach my $line (split(/\n/,$auxilliary)) {
	if ($line =~ /      <placeholder/) 
	#inserts all conceptEntry in place of placeholder element
	{
		while (<$tft>) 
		
		{
			print $out "$_" if ($_ ne "\n");
		}
		
	}
	
	else 
	
	{
		print $out $line;
	}
	
	print $out "\n";
}

#remove temp files in full version
if ($version>1) {
	unlink 'temp_file_text.txt';
	print "Printed to $out_name.\n";
}

#plays console bell, useful for debugging
#this program runs for a while on gigabyte+ files.
print "\a"x3;
