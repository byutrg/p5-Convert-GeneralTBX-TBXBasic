use warnings;
use strict;

#core XML module
use XML::Twig;

#grades similarity of two strings
#used to make guesses (Term_Entry->termEntry)
use String::Similarity;

#configures lower bound of guess validity
#lower tolerance makes bolder guesses, more mistakes
my $g_t = $ARGV[1] // 0.4;

my $version = 2.43;
#adds simple UI for testing purposes

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

my %comp=(
0 					=> ['martif'],
'martif' 			=> ['martifHeader','text'],
'martifHeader' 		=> ['fileDesc','encodingDesc','revisionDesc'],
'fileDesc' 			=> ['titleStmt','publicationStmt','sourceDesc'],
'p' 				=> ['#PCDATA'],
'titleStmt' 		=> ['title','note'],          
'title' 			=> ['#PCDATA'],                   
'publicationStmt' 	=> ['p'],               
'sourceDesc' 		=> ['p'],                    
'encodingDesc' 		=> ['p'],                  
'revisionDesc' 		=> ['change'],             
'change' 			=> ['p'],                        
'text' 				=> ['body','back'],                
'body' 				=> ['termEntry'],
'back' 				=> ['refObjectList'],
'refObjectList' 	=> ['refObject'],
'refObject' 		=> ['item'],
'item' 				=> ['#PCDATA','hi','foreign','bpt','ept','ph'],
'termEntry' 		=> [qw(langSet descrip descripGrp admin transacGrp note ref xref)],
'langSet' 				=> [qw(tig descrip descripGrp admin transacGrp note ref xref)],
'tig'		  => [qw(term termNote descrip descripGrp admin transacGrp note ref xref)],
'term' 				=> ["#PCDATA", qw(hi)],
'termNote' 			=> ["#PCDATA", qw(hi foreign bpt ept ph)],
'descrip' 			=> ["#PCDATA", qw(hi foreign bpt ept ph)],
'descripGrp' 		=> [qw(descrip admin)],
'admin' 			=> ["#PCDATA", qw(hi foreign bpt ept ph)],
'transacGrp' 		=> [qw(transac transacNote date)],
'note' 				=> ["#PCDATA", qw(hi foreign bpt ept ph)],
'ref' 				=> ["#PCDATA"],
'xref' 				=> ["#PCDATA"],
'transac' 			=> ["#PCDATA", qw(hi foreign bpt ept ph)],
'transacNote' 		=> ["#PCDATA", qw(hi foreign bpt ept ph)],
'date' 				=> ["#PCDATA"],
'hi' 				=> ["#PCDATA"],
'foreign' 			=> ["#PCDATA", qw(hi foreign bpt ept ph)],
'bpt' 				=> ["#PCDATA"],
'ept' 				=> ["#PCDATA"],
'ph' 				=> ["#PCDATA"],
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
'pb'						=> 'ph',      # = Page break			bpt ph types 
);								

#guess from these if value invalid, to avoid spurrious 'color' elements
my @datguess = (
'TBX-Basic'					,
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

my %req_kids = (
'termEntry' 		=> [qw(langSet)],
'langSet' 			=> [qw(tig)],
'tig' 				=> [qw(term)],
                	
'descripGrp' 		=> [qw(descrip)],
                	
'transacGrp' 		=> [qw(transac)],
                	
'martif' 			=> [qw(martifHeader text)],
'martifHeader' 		=> [qw(fileDesc)],
'fileDesc' 			=> [qw(sourceDesc encodingDesc)],
'titleStmt' 		=> [qw(title)],

'publicationStmt' 	=> [qw(p)],
'sourceDesc' 		=> [qw(p)],
'encodingDesc' 		=> [qw(p)],
'revisionDesc' 		=> [qw(change)],
'change' 			=> [qw(p)],

'text' 				=> [qw(body)],
#'body' 				=> [qw(termEntry)],
       				
'back' 				=> [qw(refObjectList)],
'refObjectList' 	=> [qw(refObject)],
'refObject' 		=> [qw(item)],
'#PCDATA'			=> [],
'hi'			    => ['#PCDATA'],
'bpt'               => ['#PCDATA'],
'ept'               => ['#PCDATA'],
'ph'                => ['#PCDATA'],
'date'              => ['#PCDATA'],
'ref'               => ['#PCDATA'],
'transac'           => ['#PCDATA'],
'transacNote'       => ['#PCDATA'],
'xref'              => ['#PCDATA'],
'title'             => ['#PCDATA'],

);

my %picklist = (
"administrativeStatus" 		=> [qw(preferredTerm-admn-sts admittedTerm-admn-sts
								deprecatedTerm-admn-sts supersededTerm-admn-sts)],
"grammaticalGender"         => [qw(masculine feminine neuter other)],

"partOfSpeech"              => [qw(noun verb adjective adverb properNoun other)],

"termType"                  => [qw(abbreviation acronym fullForm
										shortForm variant phrase)],
"transactionType"           => [qw(origination modification)],

);

my %adopt = (
'termEntry' 		=> [qw(look xml:lang und)],
'langSet' 			=> [qw(look)],
'tig' 				=> [qw(look missing)],
'descripGrp' 		=> [qw(look kill)],                	   
'transacGrp' 		=> [qw(look type transactionType modification)],
'martif' 			=> [qw(seek)], #text was in there spurriously?
'martifHeader' 		=> [qw(seek)],
'fileDesc' 			=> [qw(look)],
'titleStmt' 		=> ["seek","Made by Steamroller Version $version."],
'publicationStmt' 	=> ["look","Made by Steamroller Version $version."],
'sourceDesc' 		=> ["look","Made by Steamroller Version $version."],
'encodingDesc' 		=> [qw(look type XCSURI TBXBasicXCSV02.xcs)],
'revisionDesc' 		=> [qw(look change)],
'change' 			=> ["look","Added by Steamroller Version $version."], 
'text' 				=> [qw(seek)],
'back' 				=> [qw(look type respPerson)],
'refObjectList' 	=> [qw(look id Steamroller)],
'refObject' 		=> [qw(look type fn),"Steamroller Version $version."],
'hi'			    => ["kill"],
'bpt'               => ["kill"],
'ept'               => ["kill"],
'ph'                => ["kill"],
'date'              => ["kill"],
'ref'               => ["kill"],
'transac'           => ["kill"],
'transacNote'       => ["kill"],
'xref'              => ["kill"],
'title'             => ["kill"],


);

my @unique = #PCDATA not unique because it stacks!
('transac','martifHeader','text','fileDesc','title','body','descrip','term',
'encodingDesc','revisionDesc','titleStmt','publicationStmt','back');

my %elt_order = (
'martif'			=> [qw(martifHeader text)],
'martifHeader'    	=> [qw(fileDesc encodingDesc revisionDesc)],
'text'            	=> [qw(body back)],
'fileDesc'        	=> [qw(titleStmt publicationStmt sourceDesc)],
'titleStmt'       	=> [qw(title note)],
'termEntry'       	=> [qw(descrip descripGrp admin transacGrp note ref xref langSet)],
'langSet' 		  	=> [qw(descrip descripGrp admin transacGrp note ref xref tig)],
'tig' => [qw(term termNote descrip descripGrp admin transacGrp note ref xref )],
'descripGrp' 	  	=> [qw(descrip admin)],
'transacGrp' 	  	=> [qw(transac transacNote date)],
);

#a reference for things that can only go in termEntry or outside of one
my @term_elts = (
'termEntry' 		,
'langSet' 		  	,
'tig' 			  	,
'term' 			  	,
'termNote' 		  	,
'descrip' 		  	,
'descripGrp' 	  	,
'admin' 		  	,
'transacGrp' 	  	,
'ref' 			  	,
'xref' 			  	,
'transac' 		  	,
'transacNote' 	  	,
'date' 			  	,
);
my @aux_elts = (
'martif'		  ,
'martifHeader'    ,
'text'            ,
'fileDesc'        ,
'encodingDesc'    ,
'revisionDesc'    ,
'titleStmt'       ,
'publicationStmt' ,
'sourceDesc'      ,
'title'           ,
'change'          ,
'p'               ,
'body'            ,
'back'            ,
'termEntry'       ,
'refObjectList'   ,
'refObject'       ,
'item'            ,
);

my %renp=(
'martif'			=> [''],
'martifHeader'    	=> ['martif'],
'text'            	=> ['martif'],
'fileDesc'        	=> ['martifHeader'],
'encodingDesc'    	=> ['martifHeader'],
'revisionDesc'    	=> ['martifHeader'],
'titleStmt'       	=> ['fileDesc'],
'title'				=> ['titleStmt'],
'publicationStmt' 	=> ['fileDesc'],
'sourceDesc'      	=> ['fileDesc'],
'change'          	=> ['revisionDesc'],
'p'               	=> ['publicationStmt','sourceDesc','encodingDesc','change'],
'body'            	=> ['text'],
'back'            	=> ['text'],
'termEntry'       	=> ['body'],
'refObjectList'   	=> ['back'],
'refObject'       	=> ['refObjectList'],
'item'            	=> ['refObject'],
'langSet' 		  	=> [qw(termEntry)],
'tig' 			  	=> [qw(langSet)],
'term' 			  	=> [qw(tig)],
'termNote' 		  	=> [qw(tig)],
                  	
'descrip' 		  	=> [qw(termEntry langSet tig descripGrp)],
'context'         	=> [qw(tig)],
'definition'      	=> [qw(langSet termEntry)],
'subjectField'    	=> [qw(termEntry)],                  	
'descripGrp' 	  	=> [qw(termEntry langSet tig)],

'admin' 		  	=> [qw(termEntry langSet tig descripGrp)],
'transacGrp' 	  	=> [qw(termEntry langSet tig)],
'note' 			  	=> [qw(termEntry langSet tig titleStmt)],
'ref' 			  	=> [qw(termEntry langSet tig)],
'xref' 			  	=> [qw(termEntry langSet tig)],
'transac' 		  	=> [qw(transacGrp)],
'transacNote' 	  	=> [qw(transacGrp)],
'date' 			  	=> [qw(transacGrp)],
'hi' 			  	=> [qw(p term termNote descrip admin
	 						note transac transacNote foreign)],
'foreign' 		  	=> [qw(p termNote descrip admin note transac transacNote foreign)],
'bpt' 			  	=> [qw(p termNote descrip admin note transac transacNote foreign)],
'ept' 			  	=> [qw(p termNote descrip admin note transac transacNote foreign)],
'ph' 			  	=> [qw(p termNote descrip admin note transac transacNote foreign)],
'#PCDATA' 		  	=> [qw(p term termNote descrip admin note ref title
					xref transac transacNote date hi foreign bpt ept ph p item)],
);

my %locations=(
'martif'			=> [qw(merge root)],
'martifHeader'    	=> [qw(merge martif pack martif)],
'text'            	=> [qw(merge martif pack martif)],
'fileDesc'        	=> [qw(merge martifHeader pack martifHeader)],
'encodingDesc'    	=> [qw(merge martifHeader pack martifHeader)],
'revisionDesc'    	=> [qw(merge martifHeader pack martifHeader)],
'titleStmt'       	=> [qw(merge fileDesc pack fileDesc)],
'publicationStmt' 	=> [qw(merge fileDesc pack fileDesc)],
'sourceDesc'      	=> [qw(seek fileDesc pack fileDesc)],
'title'           	=> [qw(merge titleStmt pack titleStmt)],
'note'            	=> [qw(rise seek titleStmt convert)],
'change'          	=> [qw(seek revisionDesc pack revisionDesc)],
'p'               	=> [qw(rise convert)],
'body'            	=> [qw(merge text pack text)],
'back'            	=> [qw(merge text pack text)],
'termEntry'       	=> [qw(handle)],
'refObjectList'   	=> [qw(seek back pack back)],
'refObject'       	=> [qw(seek refObjectList pack refObjectList)],
'item'            	=> [qw(seek refObject convert)],                    
'langSet' 		  	=> [qw(rise pack termEntry)],
'tig' 			  	=> [qw(rise pack langSet)],
'term' 			  	=> [qw(rise gather termNote pack tig)],
'termNote' 		  	=> [qw(rise convert)],                  
'descrip' 		  	=> [qw(rise defaultTerm)],
'descripGrp' 	  	=> [qw(rise defaultTerm)],
'admin' 		  	=> [qw(rise defaultTerm)],
'transacGrp' 	  	=> [qw(rise defaultTerm)],
'ref' 			  	=> [qw(rise defaultTerm)],
'xref' 			  	=> [qw(rise defaultTerm)],                  
'transac' 		  	=> [qw(gather transacNote date pack transacGrp)],
'transacNote' 	  	=> [qw(rise convert)],
'date' 			  	=> [qw(rise convert)],                 
'hi' 			  	=> [qw(rise gather hi foreign bpt ept ph),"#PCDATA",qw(pack p)],
'foreign' 		  	=> [qw(rise gather hi foreign bpt ept ph),"#PCDATA",qw(pack p)],
'bpt' 			  	=> [qw(rise gather hi foreign bpt ept ph),"#PCDATA",qw(pack p)],
'ept' 			  	=> [qw(rise gather hi foreign bpt ept ph),"#PCDATA",qw(pack p)],
'ph' 			  	=> [qw(rise gather hi foreign bpt ept ph),"#PCDATA",qw(pack p)],
'#PCDATA' 		  	=> [qw(rise gather hi foreign bpt ept ph),"#PCDATA",qw(pack p)],	
);

my %pcstorage=(
'martif'			=> 'sourceDesc',
'martifHeader'    	=> 'sourceDesc',
'text'            	=> 'sourceDesc',
'fileDesc'        	=> 'sourceDesc',
'encodingDesc'    	=> 'p',
'revisionDesc'    	=> 'change',
'titleStmt'       	=> 'note',
'title'				=> '#PCDATA',
'publicationStmt' 	=> 'p',
'sourceDesc'      	=> 'p',
'change'          	=> 'p',
'p'               	=> '#PCDATA',
'body'            	=> 'sourceDesc',
'back'            	=> 'sourceDesc',
'termEntry'       	=> 'note',
'refObjectList'   	=> 'item',
'refObject'       	=> 'item',
'item'            	=> '#PCDATA',
'langSet' 		  	=> 'note',
'tig' 			  	=> 'note',
'term' 			  	=> '#PCDATA',
'termNote' 		  	=> '#PCDATA',                 	
'descrip' 		  	=> '#PCDATA',
'descripGrp' 	  	=> 'admin',
'admin' 		  	=> '#PCDATA',
'transacGrp' 	  	=> '',
'note' 			  	=> '#PCDATA',
'ref' 			  	=> '#PCDATA',
'xref' 			  	=> '#PCDATA',
'transac' 		  	=> '#PCDATA',
'transacNote' 	  	=> '#PCDATA',
'date' 			  	=> '#PCDATA',
'hi' 			  	=> '#PCDATA',	 					
'foreign' 		  	=> '#PCDATA',
'bpt' 			  	=> '#PCDATA',
'ept' 			  	=> '#PCDATA',
'ph' 			  	=> '#PCDATA',
'#PCDATA' 		  	=> '#PCDATA',				
);

#intelligently stores disallowed data in a safe location nearby
sub dump_truck {
	#value is optional,used for atts
	my ($t,$section,$log,$att,$code) = @_;

	#initialize message
	my $message = $att ?
	sprintf "Removed att '%s:%s' from %s%s",
	$att, $section->att($att),$section->name(),
	$log->{$section} ? " (line:".$log->{$section}{'line'}.")" : "",
	:
	sprintf "Removed %s%s",
	$section->name(),
	$log->{$section} ? " (from line:".$log->{$section}{'line'}.")" : "",;
	
	my ($fate,$position) = 
	$section->level()==0		? ('sourceDesc', $att ? 'first_child' : 'root')	:
	$att 								? @{$dump{$section->name()}} 			:
	$dump{$section->parent()->name()}	? @{$dump{$section->parent()->name()}} 	:
	('p','first_child');
	
	my $target = $section;
	if ($fate eq 'parent') {
		($fate,$position) = @{$dump{$section->parent()->parent()->name()}};
		$target = $section->parent();
	}
	
	if ($log->{$section}) {
		if ($att) {
			$log->{$section}{'atts'}{$att}{'code'} = $code // "INVALID";
			$log->{$section}{'atts'}{$att}{'a_fate'} = $fate;
		}
		else
		{
			$log->{$section}{'n_code'} = "INVALID";
			$log->{$section}{'n_fate'} = $fate;
		}
	}
	
	unless ($att) {
		#continue to extract data from atts
		#write error messages
#		print "*"x10,$section->name(),$section->atts(),"-","\n";
		if ($section->atts())
		{
			foreach my $a (keys $section->atts()) {
				$message .= sprintf ", %s=%s", $a, $section->att($a);
				if ($log->{$section}{'atts'}{$a}) {
        	
					$log->{$section}{'atts'}{$a}{'code'} = $code // "INVALID";
					$log->{$section}{'atts'}{$a}{'a_fate'} = $fate;
				}
			}
		}
	}
	$message .= ": " if $section->has_children("#PCDATA") and not $att;
	my $note = XML::Twig::Elt->new('p'=>$message);
	
	unless ($att) {
		foreach my $a ($section->children()) {	
			$a->move(last_child=>$note)        	
			if $a->name() =~ /^(#PCDATA|hi|foreign|bpt|ept|ph)$/;   		
		}                                     		
	}
	
	
	if ($fate eq 'sourceDesc') {
		my $temp = XML::Twig::Elt->new('sourceDesc');
		$note->paste($temp);
		$note = $temp;
	}
	else
	{
		$note->set_name($fate);
		$note->set_att(type=>'source') if $fate eq 'admin';
	}
	
	if ($position eq 'root') {

		$section->move($note);
		$t->set_root($note);
	}
	
	else
	
	{
		$note->paste($position=>$target);
	}

	$att ? $section->del_att($att) : $section->erase();
	
	return $note;
	
}

sub log_init {
	my ($t,$section,$log) = @_;
	#uses the Elt hash ref as the key
	
	#print $section->name(),"\n";
	
	$log->{$section} = {
		'name' 		=> $section->name(),
		'n_fate'	=> 0,
		'n_code'	=> 0,
		'line' 		=> $t->current_line(),
		'parent'	=> $section->level()>0 ? $section->parent()->name() : 0,
		'p_code'	=> 0,
		'p_fate'	=> 0,
		'text'		=> '', #has to be retrieved later
		't_code'	=> 0,
		't_fate'	=> 0,
		'atts' 		=> {}, #populated in while statement
		'other'		=> [], #stores changes that don't correspond to existing data
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
	
	$tolerance //= $g_t;
	$condition //= 1;
	#print "@_ tolerance $tolerance condition $condition\n";
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
	
	return 1 if grep {$cname eq $_} keys %comp;
	
	
	if (my $guess = autocorrect($cname,$comp{$pname},[keys %comp],
	$g_t)) #special condition removed
	
	{
		$section->set_name($guess);
		
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
#	print join(' ',keys $section->atts()),"\n";
	if (my $guess = autocorrect($att,$atts{$cname},[],$g_t,
		'not $_[5]->has_att($guess)',$section)) {
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
				
				dump_truck($t,$section,$log);
				
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
						dump_truck($t,$section,$log);
					}
				}
				elsif ($att eq 'type') 
				{#throws an error if there is no target...
					if ($section->att('target') and 
					$section->att('target') =~ m/\.(jpg|png|gif|svg)$/) {
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
					"OVERHAUL" :
					$log->{$section}{'atts'}{$att}{'val'} ?
					"REVAL" : "MISSING";
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

sub match_up {
	my ($t, $section, $log) = @_;
	
	unless (my $guess = $datcats{$section->att('type')} and
	$datcats{$section->att('type')} eq $section->name()) {
		
		$section->set_name($guess);
		$log->{$section}{'n_fate'} = $guess;
		$log->{$section}{'n_code'} = "MISMATCH";
	} 
	
}

sub dca_check {
	
	my ($t,$section,$log) = @_;
    
	return 1 unless my $value = $section->att('type');
	
	my $cname = $section->name();
	
	if (grep {$value eq $_} keys %datcats) {
		
		match_up($t, $section, $log);
		
		return 1;
		
	}
	
	#temporary storage for preferred guesses to pass to autocorrect
	my @prefer = grep {$datcats{$_} eq $cname} keys %datcats;
	
	
	if (my $guess = autocorrect($value,\@prefer,\@datguess)) 
	{
		
		#printf "Name %s Value %s Guess %s\n",$cname, $value, $guess;
		
		$section->set_att(type => $guess);
		
		if ($log->{$section}{'atts'}{'type'}) {
			$log->{$section}{'atts'}{'type'}{'code'} =
			$log->{$section}{'atts'}{'type'}{'code'} eq "RENAME" ?
			"OVERHAUL":
			$log->{$section}{'atts'}{'type'}{'val'} ?
			"REVAL" : "MISSING";
			$log->{$section}{'atts'}{'type'}{'v_fate'}=$guess;
		}
		
		match_up($t, $section, $log);
		
		return 1;
		
	}
	
	
	return 0;
	
}

sub child_check {
	my ($t, $section, $child, $log) = @_;
	my $cname = $child->name();
	
	if (my $order = $elt_order{$cname}) {
		#print "Order list found for $cname.\n";
		#print $log->{$child}{'line'},"\n" if  $log->{$child};
		#print "It is $order.\n";
		
		$child->sort_children(
		sub 
		{
			for my $i (0..$#{$order}) 
			{
				#print $i, $order->[$i],$_->name(),"\n",;
				return $i if $order->[$i] eq $_->name();
			}
			return $#{$order}+1;
		}, 
		type => 'numeric');
		#print "\n";
	}
	
	if (my $type = $child->att('type') and 
	    my $target = $picklist{$child->att('type')}) 
	{
#		print $cname,"\t",$type,"\n";
		unless (grep {$child->text_only() eq $_} @{$target}) {
#			print "Text should not be ",$child->text(),"!\n";
			my $guess;
			if ($guess = autocorrect($child->text(),$target,[],$g_t/2)) 
			{
#				print "I guess $guess\n";
			}
			
			#other possibilities of defining $guess can be added here if desired
			if ($guess) {
				foreach my $out (grep {place_check($_)} $child->children()) {
					if ($child->parent()) 
					{
						$out->move($child->parent());
						if ($log->{$out}) 
						{
							$log->{$out}{'p_code'} = "PICKLIST";
							$log->{$out}{'p_fate'} = $child->parent()->name();
						} 
					}
					else
					{
						if ($log->{$out}) {
							$log->{$out}{'p_code'} = "PICKLIST";
							$log->{$out}{'p_fate'} = "trash";
						}
					}
				}
				$child->set_text($guess);
				if ($log->{$child}) {
					$log->{$child}{'t_code'} = "PICKLIST";
					$log->{$child}{'t_fate'} = $guess;
				}
				return $child->parent() // 0;
			}
			
			#on failure to fix
			return dump_truck($t,$child,$log,0,"PICKLIST");
			
		}
		
	}
	elsif (my $req = $req_kids{$cname}) {
		foreach my $kname (@{$req}) {
			unless ($child->has_child($kname)) {
				my @to_do = @{$adopt{$cname}};
				
				#print $kname, join(" ",@to_do),"\n";
				my $kid = XML::Twig::Elt->new($kname);
				#print "$cname\n";
				while (my $action = shift @to_do) {
					if ($action eq 'seek') {
						
						if (my $oliver = $section->first_descendant($kname)) 
						{
							
							
							if (defined $log->{$oliver}) {
								$log->{$oliver}{'p_code'} = "FOUND";
								$log->{$oliver}{'p_fate'} = $cname;
							}
							
							push $log->{$child}{'other'},
							grep ($_ == $oliver,$child->descendants()) ?
							"FOUND":"SOUGHT", 
							$oliver,$oliver->parent()
							if defined $log->{$child};
							
							$oliver->move(first_child=>$child);
							return $oliver;
						} 
					}
					elsif ($action eq 'look') 
					
					{
						
						if (my $oliver = $child->first_descendant($kname)) 
						{
							
							
							if (defined $log->{$oliver}) {
								$log->{$oliver}{'p_code'} = "FOUND";
								$log->{$oliver}{'p_fate'} = $cname;
							}
							
							push $log->{$child}{'other'},"FOUND", 
							$oliver,$oliver->parent();
							$oliver->move(first_child=>$child);
							return $oliver;
						} 
					
					}
					elsif ($action eq 'kill') {
						#decompose the att and return from subroutine
						$child->erase();
						$log->{$child}{'n_code'} = "NOKID";
						$log->{$child}{'n_fate'} = $kname;
						return 0;
						#perhaps run through eraser when one is made
					}
					elsif (grep {$action eq $_} @{$atts{$kname}}) {
						my $val = shift @to_do;
						
						$kid->set_att($action=>$val);
						#attach it to $kid
					}
					else 
					{
						#$action is pcdata to $kid
						$kid->set_text($action);
					}
				}
				#print $kid->name()," $cname,\n";
				$kid->paste(first_child=>$child);
				my $entry = $kid;
				
				do {
					$entry = $entry->parent();
					return 0 unless defined $entry;
					
				} until (defined $log->{$entry});
				push $log->{$entry}{'other'}, 
				$entry == $child? "MISSING" : "CREATED", $kid, $child;
				return $kid;			

			}
		}
	}
	
	return 0;
}

sub place_check {
	
	#both arguments are elements; provide $target to test validity of a move
	my ($child,$target) = @_;
	#will need to implement $target too for use
	
	return 0 unless $target //= $child->parent();
	#hence call either provided $target, or $child has parent
	
	my $cname;
	if ($child->name() eq 'descrip' and $target->name() ne 'descripGrp') {
		$cname = $child->att('type') // $child->name(); #this default should not trigger
	}
	elsif ($child->name() eq 'descripGrp') {
#		print $child->first_child()->name(),"\n";
		$cname = $child->first_child('descrip')?
		$child->first_child('descrip')->att('type') : $child->name(); 
	}
	$cname //= $child->name();
	
	my $tname = $target->name();
	
#	print $child->name(),"\t",$cname,"\t",$tname,"\n";
	
	unless (grep {$tname eq $_} @{$renp{$cname}}) {
		return "MISPLACED";
	}
			
	return 0; #return 0 is passing, means no error code
}

sub sib_check {
	
	my ($child,$target) = @_;
	
	#return 0 unless $child needs to be unique
	my $cname = $child->name();
	return 0 unless (grep {$cname eq $_} @unique);
	
	if ($cname eq 'descrip') {
		return 0 if $child->parent()->name() ne 'descripGrp';
	}
	
	#print "-=--=-=-=-=-=-=-$cname\n";
	if ($target) 
	#check children of potential target
	{
		return "DUPLICATE" if $target->has_children($cname);
	}
	
	else
	#check siblings of the child
	{
		return "DUPLICATE" if $child->prev_sibling($cname);
	}
	
	return 0; #return 0 is passing, means no error code
}

my $default_term = XML::Twig::Elt->new('termEntry');
sub relocate {
	
	my ($t,$section,$child,$log) = @_;
	my $cname = $child->name();
	print $log->{$child}{'line'},"\n" if $log->{$child};
	my @exec = @{$locations{$cname}};
	#print join(' ',@exec),"\n\n";
	my @group;
	
	while (my $com = shift @exec) {
		
		if ($com eq 'defaultTerm') {
			
			if ($log eq \%aux_log) {
				#print "Moving to a default termEntry.\n";
				if ($log->{$child}) {
					$log->{$child}{'p_code'} = "RELOCATE";
					$log->{$child}{'p_fate'} = "default termEntry";
				}
				$child->move($default_term);
			} else {
				#print "Dumping in this termEntry.\n";
	print "dump!\n";
	
				my @out;
				foreach my $temp ($child->children()) {
					push @out, "NEW", $temp;
				}
				
				push @out,"NEW",dump_truck($t,$child,$log,'',"RELOCATE");
				return \@out;
				
			}
		}
		elsif ($com eq 'rise') {
			#print "✓ Rising until valid.\n";
			
			my $target = $child;
			
			while ($target = $target->parent()) {
#				print "-Checking ",$target->name(), "\n";
				unless (place_check($child,$target) || sib_check($child,$target)) 
				{
#					print "!Found home in ",$target->name(), "\n";
					$child->move(last_child=>$target); 
					#last_child moves marked up text nicely
					if ($log->{$child}) {
						$log->{$child}{'p_code'} = "RISE";
						$log->{$child}{'p_fate'} = $target->name(); #line number?
					}
					return ["CHILDREN"]; #now push children to stack
				}
			}
			
		}
		elsif ($com eq 'merge' or $com eq 'seek') {
			my $target = shift @exec;
			#my $loser = shift @exec if $com eq 'merge';
			
			#debug statement
			#$com eq 'merge' ? 
			#print "✓ Fighting for spot in $target\n":
			#print "✓ Looking for $target.\n";
			
			if ($log eq \%term_log) {
				my @out = ();
#				print "This should not be in a term.\n";
				foreach my $elt ($child->descendants()) {
					if (grep {$_ eq $elt->name()} @term_elts) {
						$elt->move(after=>$child);
						if ($log->{$elt}) {
							$log->{$elt}{'p_code'} = "ORPHANED";
							$log->{$elt}{'p_fate'} = $child->parent->name() // '';
						}
						push @out, "NEW", $elt;
					}
				}
			
				$child->move(last_child=>$t->root());
				
				#transfer record to %aux_log
				if ($log->{$child}) {
#					print "123456 transferring\n";
					$log->{$child}{'p_code'} = "MOVED";
					$log->{$child}{'p_fate'} = 'aux';
					push $log->{$child}{'other'}, "EXILED";
					$aux_log{$child} = $log->{$child};
					delete $log->{$child};
				}
				#print join(" ",@out),"&"x10,"\n";
			return \@out;
			}
			else
			{
#				print "Good thing we are in the aux!\n";
				if (my $elt = 
				$section->name() eq $target ?
				$section : $section->first_descendant($target)
				or $target eq 'root'
				)
				#assign $elt to the root/termEntry or its first descendant
				#whichever can best parent $child.
				#if $target is root, then we are dealing with a misplaced martif
				#so let it in anyway with $elt undefined
				{
#					print "!!! Found $target \n";
					
					if ($com eq 'merge' and 
					my $contender =
					$target eq 'root' ? $t->root() :
					$elt->first_child($child->name())) 
					#if we are targeting the root, the contender is root.
					#otherwise, it is an element with same name
					{
						
						foreach my $att (@{$atts{$cname}}) {
							if ($contender->att($att) and $child->att($att)) {
								dump_truck($t,$child,$log,$att,"MERGE")
								if $log->{$child} 
								and $log->{$child}{'atts'}{$att}{'val'};
								
								
							}
							
						}
						
						if ($log->{$child}) {
							$log->{$child}{'p_code'} = "MERGED";
							$log->{$child}{'p_fate'} = $section->name();
						}
						
						$contender->merge($child);
#						print "&&&MERGING\n";
						
						return ["NEW",$contender];
					}
					else
					{
						$child->move(last_child=>$elt);
						if ($log->{$child}) {
							$log->{$child}{'p_code'} = "MOVED";
							$log->{$child}{'p_fate'} = $elt->name();
						}
#						print "^^^MOVING\n";
						return ["SELF"];
					}
				}
			}
			
		}
		elsif ($com eq 'handle') {
			#print "✓ Processing as a termEntry.\n";
			foreach my $elt ($child->descendants_or_self()) {
				$elt->sprint(); #why on earth does this fix it? initializes something...
				term_log_init($t,$elt);
				handle_term($t,$elt); #puts text in log
			}
			order_term($t,$child);
			
		}
		elsif ($com eq 'convert') {
#			print "\n"x10;
			#print "✓ Converting $cname PCDATA.\n";
#			$child->parent()->print();
			#what if...
			if (my $fate = $pcstorage{$child->parent()->name()}) {
				if ($log->{$child}) {
					$log->{$child}{'p_code'} = "CONVERT";
					$log->{$child}{'p_fate'} = "$fate";
				}

				#$child->set_name($fate);
				#$child->parent()->print();
				if ($fate eq 'sourceDesc') {
					$child->wrap_in("sourceDesc");
					return ["SELF"];
				} elsif ($fate =~ /p|note/) {
					$child->set_name($fate);
					return ["CHILDREN"];
				} elsif ($fate eq 'change') {
					$child->wrap_in('change');
					return ["SELF"];
				} elsif ($fate eq '#PCDATA') {
					my $new = XML::Twig::Elt->new("#PCDATA"=>$child->text());
					$new->replace($child);
#					$new->parent()->print();
					return ["NEW",$new];
				} elsif ($fate eq 'item') {
					$child->set_name('item');
					$child->set_att('type'=>'related');
					return ["SELF"];
				} elsif ($fate eq 'admin') {
					$child->set_name('admin');
					$child->set_att('type'=>'source');
					return ["SELF"];
				} else {
					#print "convert was not expecting $fate.\n";
				}
				#print "\n"x10;
				
			}
			
			dump_truck($t,$child,$log,'',"CONVERT");

			return ["NEW",];
			
		}
		elsif ($com eq 'gather') 
		#gather must be followed by elements to get, then 'pack'!
		{
			my @get_list;
			
			while ($exec[0] ne 'pack') {
				push @get_list, shift @exec;
			}
			#print "✓ Gathering neighbors, ".join(" ",@get_list)."\n";
			
			my $target = $child;
			
			while ($target = $target->next_sibling())
			{ 
#			  
				if (grep {$target->name() eq $_} @get_list) {
					if (place_check($target) || sib_check($target))
					#don't kidnap elements happy where they are 
					{
						push @group, $target;
#						print "=Found ",$target->name(),"\n";
					}
				}
									
			}
			
			
		}
		elsif ($com eq 'pack') {
			my $target = shift @exec;
			#print "✓ Wrapping in a $target element.\n";
			my $parent = $child->wrap_in($target);
			if ($log->{$child}) {
				$log->{$child}{'p_code'} = "PACKED";
				$log->{$child}{'p_fate'} = $target;
			}
			while (my $a = shift @group) {
				$a->move(last_child=>$parent);
			}
			#return ["NEW",$parent];
			return ["CHILDREN"];
		}
		else 
		{
			#print "Relocator was not expecting $com.\n";
		}
		
	}
	
	return ["CHILDREN"]; #default, may not be appropriate after
	#all methods are implemented
	
}

sub order_check {
	my ($t, $section, $log) = @_;
	
	my @children = ($section);
	my $child;
	
	while ($child = shift @children) {

		my $cname = $child->name();
		
		if (my $code = place_check($child) || sib_check($child)) 
		
		{
#			print "^^^",$child->name(),")\n";
			#printf "%s %s %s %s\n", $log->{$child}?$log->{$child}{'line'}:'',
			#$child->name(), $code, join(' ',@{$locations{$child->name()}});
			
			if (my $result = relocate($t,$section,$child,$log)) 
			#currently, if relocate fails, it should just return the child?
			#success will return true only if something needs to go back on stack
			{
				
				while (my $item = shift @{$result}) {
					
					if ($item eq "SELF") {
						push @children,$child;
						
					}
					elsif ($item eq "CHILDREN") {
						
						push @children,$child->children();
						if (my $temp =child_check($t,$section,$child->parent(),$log)) {
							#print "==",$temp->name(),"\n";
							push @children,$temp;
						}
						
					}
					elsif ($item eq "NEW")
					{
						
						push @children, shift @{$result};
						#print $children[-1]->name(),"\n";						
					}
					else {
						#print "Order_check was not expecting $item.\n";
					}
				}
				
				
				
			
			}
			#print "\n";
		}
		else {
#			print "--",$cname, $log->{$child} ? $log->{$child}{'line'}:'',"\n";		
			push @children, $child->children();
			if (my $temp =child_check($t,$section,$child,$log)) {
				push @children,$temp;
			}

		}
		
		
		
		
	}
	
	if ($log eq \%aux_log and $default_term->has_children()) {
		relocate($t,$section,$default_term,$log);
	}
	
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

		dump_truck($t,$section,\%term_log);

		return 1;
		
	}
	
	foreach my $att (keys $section->atts()) {
		#check that the att is TBX approved
		unless (att_check(@_,$att,\%term_log)) 
		{
			dump_truck($t,$section,\%term_log,$att);

		}
	}
	
	unless (dca_check($t,$section,\%term_log)) {
		
			dump_truck($t,$section,\%term_log,);
		
	}
	
	prereq($t,$section,\%term_log);
	
	return 1;
}

sub order_term {
	my ($t,$section) = @_;
	$section->cut();
	handle_term(@_);
	order_check(@_,\%term_log);
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
		dump_truck($t,$section,\%aux_log);
		return 1;
	}
	
	foreach my $att (keys $section->atts()) {
		#check that the att is TBX approved
		unless (att_check(@_,$att,\%aux_log)) 
		{
			dump_truck($t,$section,\%aux_log,$att);
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
			
			dump_truck($t,$section,\%aux_log);
			
		}
		
		
	}
	
	return 1;
}

sub order_root {
	my ($t,$section) = @_;
	
	handle_aux(@_);
	
	order_check(@_,\%aux_log);
	
	return 1;
}

sub print_log {
	my (%log) = @_;
	print $lf "-"x20,"\n" if $verbose;
	my $clean = 1;
	my @sections = sort {$log{$a}{'line'} <=> $log{$b}{'line'}} keys %log;
	foreach my $section (@sections) 

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
		
		if (my $code = $log{$section}->{'n_code'}) {
			
			if ($code eq 'BADCAT') {
				my $x;
				$i .= sprintf "%s had bad data category%s. Stored as %s.\n",
				$log{$section}->{'name'},
				($x = $log{$section}{'atts'}{'type'}{'val'}) ? " '$x'" : '',
				$log{$section}->{'n_fate'};
			}
			
			elsif ($code eq 'INVALID') {
				$i .= sprintf "%s had invalid name. Stored as %s.\n",
				$log{$section}->{'name'},$log{$section}->{'n_fate'};
			}
			
			elsif ($code eq 'RENAME') {
				$i .= sprintf "%s had invalid name, renamed %s.\n",
				$log{$section}->{'name'},$log{$section}->{'n_fate'};
			}
			
			elsif ($code eq 'MISMATCH') {
				my $x = $log{$section}{'atts'}{'type'}{'v_fate'} ?
				$log{$section}{'atts'}{'type'}{'v_fate'} : 
				$log{$section}{'atts'}{'type'}{'val'};
				$i .= sprintf "%s had mismatched data category%s. ".
				"Renamed element '%s'\n",
				$log{$section}->{'name'},
				$x ? " '$x'" : '',
				$log{$section}->{'n_fate'};
			}
			elsif ($code eq 'NOKID') {
				$i .= sprintf "%s was missing child '%s', removed.\n",
				$log{$section}->{'name'},$log{$section}->{'n_fate'}
			}
			else
			{
				$i .= sprintf "%s had error $code\n",
				$log{$section}->{'name'},;
			}
			
		}
	
		foreach my $att (sort keys $log{$section}{'atts'}) 

		{
			my $contents = $log{$section}{'atts'}{$att};
			$i .= sprintf "%s has attribute %s:%s.\n",
			$log{$section}->{'name'},
			$att, $contents->{'val'},
			if $verbose;
			if (my $code = $contents->{'code'}) {
				if ($code eq "MISSING") {
					$i .= sprintf "Attribute %s missing, set to '%s'.\n",
					$att, $contents->{'v_fate'};
				}
				elsif ($code eq "INVALID") {
					$i .= sprintf "Attribute %s=%s was invalid, stored as %s.\n",
					$att, $contents->{'val'}, $contents->{'a_fate'};
				}
				elsif ($code eq "REVAL") {
					$i .= sprintf "'%s' value '%s' invalid, changed to '%s'.\n",
					$att, $contents->{'val'}, $contents->{'v_fate'};
				}
				elsif ($code eq "RENAME") {
					$i .= sprintf "Attribute name '%s' invalid, changed to '%s'.\n",
					$contents->{'a_fate'},$att;
				}
				elsif ($code eq "OVERHAUL") {
					$i .= sprintf "Attribute %s=%s changed to %s=%s.\n",
					$contents->{'a_fate'}, $contents->{'val'},
					$att, $contents->{'v_fate'};
				}
				else {
					$i .= sprintf "Unknown Error $code on $att.\n";
				}
			}
			
		}
		
		if (my $code = $log{$section}->{'p_code'}) {
			
			if ($code eq 'FOUND') {
				
				$i .= sprintf "%s moved from %s to fulfill requirements of %s.\n",
				$log{$section}->{'name'},
				$log{$section}->{'parent'},
				$log{$section}->{'p_fate'},
			}
			
			
			else
			{
				$i .= sprintf "%s had error $code %s\n",
				$log{$section}->{'name'},
				$log{$section}->{'p_fate'} ? $log{$section}->{'p_fate'} :'';
			}
			
		}
		
		if (my $code = $log{$section}->{'t_code'}) {
			
			if ($code eq 'PICKLIST') {
				$i .= sprintf "%s had wrong picklist value, changed%s to %s.\n",
				$log{$section}->{'name'},
				$log{$section}->{'text'} ? " from ".$log{$section}->{'text'} : '',
				$log{$section}->{'t_fate'};
			}
		}
		
		my @others = @{$log{$section}{'other'}};
		while (my $code = shift @others) {
			if ($code eq "MISSING") {
				my $kid = shift @others;
				my $parent = shift @others;
				$i .= sprintf "Required Element %s missing from %s, ".
				"created and added.\n",
				$kid->name(),$parent->name();
			}
			elsif ($code eq "CREATED") {
				my $kid = shift @others;
				my $parent = shift @others;
				$i .= sprintf "Required element %s added to new %s.\n",
				$kid->name(),$parent->name();
			}
			elsif ($code eq "FOUND") {
				my $kid = shift @others;
				my $parent = shift @others;
				$i .= sprintf "Required element %s taken from child node %s%s.\n",
				$kid->name(),$parent->name(),
				defined $log{$parent}{'line'} ? " on line ".$log{$parent}{'line'} : '' ;
			}
			elsif ($code eq "SOUGHT") {
				my $kid = shift @others;
				my $parent = shift @others;
				$i .= sprintf "Required element %s found in node %s%s.\n",
				$kid->name(),$parent->name(),
				defined $log{$parent}{'line'} ? " on line ".$log{$parent}{'line'} : '' ;
			}
			else {
				$i.= sprintf "Error code $code.\n";
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
until ($file && $file =~ m/(tbx|xml|tbxm)\Z/ && -e $file) {
	print "Please enter a valid tbx file:\n";
	$file = <STDIN>;
	chomp $file;
}

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

$twig->set_id_seed('s');

$twig->parsefile($file);

unless ($twig->doctype()=~/TBXBasiccoreStructV02/) 

{
	printf $lf "Setting doctype declaration to TBXBasiccoreStructV02.dtd.\n";
	$twig->set_doctype('martif',"TBXBasiccoreStructV02.dtd");
	
}

#change to safeparse so that something can be written to the logfile instead

#print logfile sorted by linenumber of original
print_log(%aux_log);

my $auxilliary = $twig->sprint();

close($tft);
open($tft,'<','temp_file_text.txt');

#my $out_name = $file;
#$out_name =~ s/(.+?)\..+/$1_steamroller.tbx/;
print "Please enter a name for the output file, or press enter to print to result.tbx.\n";
my $out_name = <STDIN>;
chomp $out_name;
unless ($out_name =~ m/\.tbx\Z/) {
	print "nope!\n";
	$out_name = 'result.tbx'
}
#'result.tbx' if $dev;

open(my $out, ">:encoding(UTF-8)",$out_name);

foreach my $line (split(/\n/,$auxilliary)) {
	if ($line =~ m!<body></body>!) 
	
	#this gross code will be nicer when placeholder is back
	
	{
		
		$line =~ s!</body>!!;
		print $out $line,"\n";
		
		while (<$tft>) 
		{
			print $out "      $_" if ($_ ne "\n");
		}
		
		$line =~ s!<body>!</body>!;
		print $out $line;
		
	}
	
	else 
	
	{
		$line =~ s!\?><!\?>\n<!g;
		print $out $line;
	}
	
	print $out "\n";
}