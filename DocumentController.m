//
//  DocumentController.m
//  Prokope
//
//  Created by D. Robert Adams on 5/10/11.
//  Copyright 2011 Grand Valley State University. All rights reserved.
//
// Need to knows : 1) don't create an div tags in the commentary section. 
//

#import "DocumentController.h"
#import "DocumentViewerDelegate.h"
#import "WebViewController.h"

@implementation DocumentController

@synthesize document, commentary, vocabulary, sidebar, URL, Title, UserName, FollowArray;

/******************************************************************************
 * This is a standard method.
 */
- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc. that aren't in use.
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
	NSLog(@"NO INTERNET PEOPLE");
    NSString *titleString = @"Error Loading Page";
    NSString *messageString = [error localizedDescription];
    NSString *moreString = [error localizedFailureReason] ?
	[error localizedFailureReason] :
	NSLocalizedString(@"Try typing the URL again.", nil);
    messageString = [NSString stringWithFormat:@"%@. %@", messageString, moreString];
	
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:titleString
														message:messageString delegate:self
											  cancelButtonTitle:@"Cancel" otherButtonTitles:nil];
    [alertView show];
    [alertView release];
}

/******************************************************************************
 * This is called when a new view is being presented.
 */
-(void)viewWillDisappear:(BOOL)animated
{	
	[MyTimer invalidate];
	MyTimer = nil;
}

/******************************************************************************
 * This is called when a this view goes away.
 */
- (void)viewDidUnload
{
    [super viewDidUnload];
}

/******************************************************************************
 * Override to allow orientations other than the default portrait orientation..
 */
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationLandscapeRight);
}

/******************************************************************************
 * Called after this view is loaded -- basically a constructor.
 */
- (void)viewDidLoad 
{
    [super viewDidLoad];
	RatingsArray = [[NSMutableArray alloc] initWithCapacity:1000];
	ClicksArray = [[NSMutableArray alloc] initWithCapacity:1000];
	MediaArray = [[NSMutableArray alloc] initWithCapacity:1000];
	FollowArray = [[NSMutableArray alloc] initWithCapacity:1000];
	
	// Create a delegate for the document viewer.
	document.delegate = [[DocumentViewerDelegate alloc] initWithController:self];
	
	// Make ourselves the delegate for the other web views.
	commentary.delegate = self;
	vocabulary.delegate = self;
	sidebar.delegate = self;
	
	// Go fetch and display the document.
	[self fetchDocumentData];
	
	NSString *datestring = [[NSDate date] description];
	
	XMLString = [[NSMutableString alloc] initWithFormat:@"<entries user='%@' url='%@' date='%@'>", UserName, URL, datestring];
	
	//	if(MyTimer)
	//	{
	//		NSLog("@No Timer needed");	
	//	}
	
	//	MyTimer = [NSTimer scheduledTimerWithTimeInterval:5.0 target:self selector:@selector(targetMethod) userInfo:nil repeats:YES];
}

/******************************************************************************
 * This method is called by the timer after a certain interval.
 */
-(void)targetMethod
{	
	// URL to do the post is :  www.cis.gvsu.edu/~prokope/index.php/rest/log
	
	/**
	 * Logs user activity to the DB.
	 * Assumes data comes in via POST with the format:
	 * <entries user="USERNAME">
	 *    <like date="2011-07-25 19:42:54" doc="DOCUMENTID" comment="COMMENTID" />
	 *    <dislike date="2011-07-25 19:42:54" doc="DOCUMENTID" comment="COMMENTID" />
	 *    <click date="2011-07-25 19:42:54" doc="DOCUMENTID" word="WORDID" />
	 *     <media date="2011-08-03 08:24:00" doc="DOCUMENTID" comment="281" />
	 *     <follow date="2011-08-03 08:27:00" doc="DOCUMENTID" url="URL" />
	 * </entries>
	 
	 * Where:
	 *		USERNAME is the email address of the user
	 *		DOCUMENTID is the (int) unique document id
	 *		COMMENTID is the (int) unique comment id
	 * 		WORDID is the id of the word within the document (usually of the form "10.2.1.14")
	 
	 * Returns "<result>1</result>" on success, 
	 * 		<result>-1</result> on user not found,
	 * 		<result>-2</result> on a runtime exception (probably malformed XML).
	 */
	
	//	NSURL * serviceUrl = [NSURL URLWithString:@"http://my.company.com/myservice"];
	//	NSMutableURLRequest * serviceRequest = [NSMutableURLRequest requestWithURL:serviceUrl];
	//	[serviceRequest setValue:@"text/xml" forHTTPHeaderField:@"Content-type"];
	//	[serviceRequest setHTTPMethod:@"POST"];
	//	[serviceRequest setHTTPBody:[xmlString dataUsingEncoding:NSASCIIStringEncoding]];
	
	//	NSURLResponse * serviceResponse;
	//	NSError * serviceError;
	//	serviceResponse = [NSURLConnection sendSynchronousRequest:serviceRequest returningResponse:&serviceResponse error:&serviceError];
}

/******************************************************************************
 * Fetches and displays all the data related to a document.
 */
- (void)fetchDocumentData
{
	// Convert the NSMutable data into a normal string.
	NSError *error;
	NSString *data = [[NSString alloc] initWithContentsOfURL:[NSURL URLWithString:URL] encoding:NSUTF8StringEncoding error:&error];

	// Make sure that links look like normal text.
	NSString *doc = @"<style type=\"text/css\">a { color: black; text-decoration: none; </style>";
	NSString *meta = @"<meta name='viewport' content='width=device-width; initial-scale=1.0; maximum-scale=4.0; user-scalable=1;' />";
	
	// This function highlights the specific <a> tag that the user just clicked. That word will remain highlighted until another
	// word is clicked. 
	NSString *script = 
	@"<script lang=\"text/javascript\">"
	"function highlightword(ref)"
	"{"
	"   var words = document.getElementsByTagName('a');"
	"   for(i = 0; i < words.length; i++)"
	"   {"
	"       if ( words[i].getAttribute('href') == ref )"
	"       {"       
	"	         words[i].style.backgroundColor = '#F5DEB3';"
	"       }"
	"       else"
	"       {"
	"            words[i].style.backgroundColor = '#FFFFFF';"
	"       }"
	"    }"
	"}"
	"</script>";

	// This javascript scales the images down to a smaller size.
	NSString *scale_script = 
	@"<script lang=\"text/javascript\">"
	"function scale_images()"
	"{"
	"   for(i = 0; i < document.images.length; i++)"
	"   {"
	"       document.images[i].style.marginLeft = '5';"
	"       document.images[i].height = '11';"
	"   }"
	"}"
	"scale_images();"
	"</script>";
	
	// This javascript takes in a url and gives a corresponding id. 
	NSString *URL_Getter = 
	@"<script lang=\"text/javascript\">"
	"    "
	"function GetIdFromHref(url)"
	"{"
	"   var elems = document.body.getElementsByTagName('a');"
	"    var anchors = document.body.getElementsByTagName('a');"
	"	 for (i = 0; i < anchors.length; i++)"
	"    {"
	"        if(anchors[i].getAttribute('href', 0) == url)"
	"        {"
	"            var id = anchors[i].getAttribute('id', 0);"
	"            return id;"
	"        }"
	"    }"
	"}"
	"   "
	"</script>";

	// This javascript function highlights the coresponding li tag(s) that contain a match for a specific id
	// It then scrolls the window (in this case the UIWebView that holds it) to that li tag.
	NSString *js = 
	@"<script lang=\"text/javascript\">"
	"function show_only(ref, view)"
	"{"
	"	var comments = document.getElementsByTagName('li');"
	"   var found = false;"
	"	for (i = 0; i < comments.length; i++) {"
	"		comments[i].style.display = 'list-item';"
	"		if ( comments[i].getAttribute('ref') == ref) {"
	"            if(view == 'commentary')"
	"            {"
	"                comments[i].style.backgroundColor = '#F5DEB3';"
	"            }"
	"            if(found == false)"
	"            {"
	"                var selectedPosX=0;"
	"			     var selectedPosY=0;"
	"                selectedPosX+=comments[i].offsetLeft;"
	"                selectedPosY+=comments[i].offsetTop;"
	"                window.scrollTo(selectedPosX,selectedPosY);"
	"                found = true;"
	"            }"
	"		}"
	"		else {"
	"			comments[i].style.backgroundColor = '#FFFFFF';"
	"           comments[i].style.fontWeight = 'normal';"
	"		}"
	"	}"
	"}"
	"</script>";
	
	// This javascript function hides all the text. It is hidden when the poem is first loaded. The 
	// rest of the content is shown when a user clicks on a word. 
	NSString *hide_text =
	@"<script lang=\"text/javascript\">"
	"function hide_text()"
	"{   "
	"   var comments = document.getElementsByTagName('li');"
	"	for (i = 0; i < comments.length; i++)"
	"   {"
	"       comments[i].style.display = 'none';"
	"   }"
	"}   "
	"hide_text();"
	"</script>";
	
	// This javascript function display the ratings for the comments, and switches the images when a like/dislike button is clicked.
	NSString *display_ratings = 
	@"<script lang=\"text/javascript\">"
	"    "
	"function display_ratings()"
	"{"
	"	var comments = document.getElementsByTagName('li');"
	"   var i = 0;"
	"	for (i = 0; i < comments.length; i++)"
	"   {"
	"      var newid = comments[i].getAttribute('id');"
	"      var newdiv = document.createElement('div');"
	"      if(i == 0)"
	"      {"
	"          newdiv.innerHTML = '<img width=15 height=15 src=\"http://www.cis.gvsu.edu/~prokope/images/Like-Clicked.png\" />';"
	"          newdiv.innerHTML = '<img width=15 height=15 src=\"http://www.cis.gvsu.edu/~prokope/images/Dislike-Clicked.png\" />';"
	"      }"
	"      newdiv.innerHTML = '<a href=\"Like' + newid +'\"><img width=15 height=15 src=\"http://www.justinantranikian.com/Photos/Like-Up.png\" /></a>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<a href=\"Dis-Like' + newid +'\"><img width=15 height=15 src=\"http://www.justinantranikian.com/Photos/Dislike-Up.png\" /></a>';"
	"      comments[i].appendChild(newdiv);" 
	"	}"
	"}"
	"      "
	"function toggleLikeDislike(int, text)"
	"{"
	"      var str = text + int;  "
	"      var children = document.getElementsByTagName('li');"
	"	   for (i = 0; i < children.length; i++)"
	"      {"
	"           if(children[i].getAttribute('id') == int)   "
	"           {"
	"                 var anchors = children[i].getElementsByTagName('img');"
	"                 var count = anchors.length;"
    "                 var like = anchors[count - 2];"
	"                 var dislike = anchors[count - 1];"
	""
	"                 var sentText = text + int;"
    "                 var subSection = sentText.substring(0,4);"
	"                 if(subSection == 'Like')"
	"                 {"
	"                      like.src = 'http://www.cis.gvsu.edu/~prokope/images/Like-Clicked.png';"
	"                      dislike.src = 'http://www.cis.gvsu.edu/~prokope/images/Dislike-Up.png';"
	"                 }"
	"                 else"
	"                 {"
	"                      like.src = 'http://www.cis.gvsu.edu/~prokope/images/Like-Up.png';"
	"                      dislike.src = 'http://www.cis.gvsu.edu/~prokope/images/Dislike-Clicked.png';"
	"                 }"
	"                 break;"
	"            }"
	"	    }"
	"}"
	"    "
	"display_ratings();"
	"</script>";
	
	doc = [doc stringByAppendingString:script];
	doc = [doc stringByAppendingString:meta];
	doc = [doc stringByAppendingString:URL_Getter];
	
	// Find the content of the document itself.
	doc = [doc stringByAppendingString:[self getXMLElement:@"<body>" endElement:@"</body>" fromData:data]];
	doc = [doc stringByAppendingString:scale_script];
	
	[document loadHTMLString:doc baseURL:nil];
	
	// Find the content of the commentary.
	doc = [self getXMLElement:@"<commentary>" endElement:@"</commentary>" fromData:data];

	doc = [doc stringByAppendingString:js];
	doc = [doc stringByAppendingString:display_ratings];
	doc = [doc stringByAppendingString:URL_Getter];
	doc = [doc stringByAppendingString:meta];
	doc = [doc stringByAppendingString:hide_text];
	[commentary loadHTMLString:doc baseURL:nil];

	// Find the content of the vocabulary.
	doc = [self getXMLElement:@"<vocabulary>" endElement:@"</vocabulary>" fromData:data];
	doc = [doc stringByAppendingString:js];
	doc = [doc stringByAppendingString:URL_Getter];
	doc = [doc stringByAppendingString:meta];
	doc = [doc stringByAppendingString:hide_text];
	[vocabulary loadHTMLString:doc baseURL:nil];

	// Find the content of the sidebar.
	doc = meta;
	doc = [doc stringByAppendingString:URL_Getter];
	doc = [doc stringByAppendingString:[self getXMLElement:@"<sidebar>" endElement:@"</sidebar>" fromData:data]];
	[sidebar loadHTMLString:doc baseURL:nil];
	
	[data release];
}

/******************************************************************************
 * Fetches an entire XML element. NOTE: This method uses substring operations,
 * not an XML parser. Therefore, all elements must be unique.
 */
- (NSString *) getXMLElement:(NSString *)startElement endElement:(NSString *)endElement fromData:(NSString *)data
{
	// Find where the start and end elements live.
	NSRange startRange = [data rangeOfString:startElement];	
	NSRange endRange = [data rangeOfString:endElement];
	
	// If we didn't find both elements, return an empty string.
	if (startRange.length == 0 || endRange.length == 0)
		return @"";
	
	// Create a range that subsumes the two elements and everything in between.
	NSRange dataRange;
	dataRange.location = startRange.location;
	dataRange.length = endRange.location - startRange.location + 1 + endRange.length;
	
	// Return the data between the two.
	return [data substringWithRange:dataRange];
}

/* **********************************************************************************************************************
 * Called when any of the webviews (except document) wants to load a URL. The method screens requests made from
 * different webviews and directs the request to the appropriate place. 
 */
- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
	// "Other" means we are loading a page ourselves (i.e., not in response to click) -- probably a document.
	if (navigationType == UIWebViewNavigationTypeOther)
		return TRUE; // load the document
	
	// Did the user click on a link?
	else if (navigationType == UIWebViewNavigationTypeLinkClicked) {
		
		// Get the URL begin requested and feed it to our imageViewController.
		NSString *StringRequest = [[request URL] absoluteString];
		if ( [StringRequest rangeOfString:@"http"].length == 0 )
		{
			NSRange theRange = [StringRequest rangeOfString:@"/" options:NSBackwardsSearch];
			NSString *path = [StringRequest substringFromIndex:theRange.location];
			
			NSCharacterSet* nonDigits = [[NSCharacterSet decimalDigitCharacterSet] invertedSet];
			NSString *ending = [path stringByTrimmingCharactersInSet:nonDigits];
			
			if ([path hasPrefix:@"/Like"])
			{
				NSString *jss = [NSString stringWithFormat: @"toggleLikeDislike('%@', 'Like');", ending];
				[commentary stringByEvaluatingJavaScriptFromString:jss];
				NSString *new = [NSString stringWithFormat:@"<like date='%@' doc='%@' comment='%@' /> \n", [self getDate], URL, ending];
				[RatingsArray addObject:new];
			}
			else if([path hasPrefix:@"/Dis-Like"])
			{
				NSString *jss = [NSString stringWithFormat: @"toggleLikeDislike('%@', 'Dis-Like');", ending];
				[commentary stringByEvaluatingJavaScriptFromString:jss];
				NSString *new = [NSString stringWithFormat:@"<dislike date='%@' doc='%@' comment='%@' /> \n", [self getDate], URL, ending];
				[RatingsArray addObject:new];
			}
		}
		// Meaning this was an actually http request. Therefore we have our own code that gets called, and we present a WebViewController
		// and show that with the contents of the request.
		else
		{
			// Load the image viewer nib and set the URL.
			NSString *extension = [StringRequest pathExtension];
			
			if ([extension isEqualToString:@"jpg"] || [extension isEqualToString:@"png"])
			{
				[self captureURL:webView RequestMade:StringRequest];
			}
			else
			{
				NSString *new = [NSString stringWithFormat:@"<follow date='%@' doc='%@' comment='%@' /> \n", [self getDate], URL, StringRequest];
				[FollowArray addObject:new];
			}

			WebViewController *webViewer = [[WebViewController alloc] initWithNibName:@"WebViewController" bundle:nil];

			webViewer.url = StringRequest;

			// If not using a popover, create a modal view.
			[self presentModalViewController:webViewer animated:YES];
			[webViewer release];
		}
	}	
	// Ignore all other types of user interation.
	return FALSE;
}

-(NSString *)getDate
{
	NSDate *currentDateTime = [NSDate date];
	NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
	[dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
	NSString *dateInString = [dateFormatter stringFromDate:currentDateTime];
	[dateFormatter release];
	
	return dateInString;
}

-(void)captureURL:(UIWebView *)webView RequestMade:(NSString *)request
{
	NSString *returnval = [webView stringByEvaluatingJavaScriptFromString:
		[NSString stringWithFormat:@"GetIdFromHref('%@')", request]];
	
	NSString *new = [NSString stringWithFormat:@"<media date='%@' doc='%@' comment='%@' /> \n", [self getDate], URL, returnval];
	[MediaArray addObject:new];
}

/* **********************************************************************************************************************
 * Called by DocumentViewerDelegate when the user clicks on a word.
 */
- (void) wordClicked:(NSString *)id
{
	
	NSString *js = [NSString stringWithFormat: @"show_only('%@', 'commentary');", id];
	[commentary stringByEvaluatingJavaScriptFromString:js];	
	js = [NSString stringWithFormat: @"show_only('%@', 'vocabulary');", id];
	[vocabulary stringByEvaluatingJavaScriptFromString:js];
	
	js = [NSString stringWithFormat:@"highlightword('%@')", id];
	[document stringByEvaluatingJavaScriptFromString:js];
		
	NSString *new = [NSString stringWithFormat:@"<click date='%@' doc='%@' comment='%@' /> \n", [self getDate], URL, id];
	[ClicksArray addObject:new];
	
	[self pumpXMLtoOutput];
}

-(void)pumpXMLtoOutput
{
	NSMutableString *XMLString1 = [[NSMutableString alloc] initWithFormat:@"<entries user='%@'>", UserName]; 
	[XMLString1 appendString:@"\n\n"];
	
	for (NSString *str in RatingsArray)
	{
		[XMLString1 appendString:str];
	}
	
	for (NSString *str in MediaArray)
	{		
		[XMLString1 appendString:str];
	}
	
	for (NSString *str in FollowArray)
	{		
		[XMLString1 appendString:str];
	}
	
	for (NSString *str in ClicksArray)
	{
		[XMLString1 appendString:str];
	}
	[XMLString1 appendString:@"\n"];
	[XMLString1 appendString:@"</entries>"];
	
	NSLog(@"%@", XMLString1);
}

/* ***********************************************************************************************
 * Clearing our memory.
 */
- (void)dealloc
{
    [super dealloc];
}


@end
