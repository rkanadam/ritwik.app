<%@page import="org.apache.commons.lang3.StringUtils"%>
<%@page import="org.apache.commons.io.IOUtils"%>
<%@page import="com.google.gdata.client.GoogleService.SessionExpiredException"%>
<%@page import="com.google.gdata.client.Service.GDataRequest.RequestType"%>
<%@page import="com.google.gdata.client.Service.GDataRequest"%>
<%@page import="com.google.gdata.util.ContentType"%>
<%@page import="com.google.gdata.client.http.GoogleGDataRequest"%>
<%@page import="com.google.gdata.client.GoogleAuthTokenFactory"%>
<%@page import="com.google.gdata.client.Service.GDataRequestFactory"%>
<%@page import="java.net.URL"%>
<%@page import="java.io.File"%>
<%@page import="com.google.api.client.googleapis.auth.oauth2.GoogleCredential"%>
<%@page import="com.google.gdata.client.Service"%>
<%@page import="com.google.api.client.http.javanet.NetHttpTransport"%>
<%@page import="com.google.api.client.json.jackson2.JacksonFactory"%>
<%@page import="com.google.api.client.json.JsonFactory"%>
<%@page import="com.google.api.client.http.HttpTransport"%>
<%@page import="java.util.List"%>
<%@page import="java.util.ArrayList"%>

<%!
private static final HttpTransport HTTP_TRANSPORT = new NetHttpTransport();
private static final JsonFactory JSON_FACTORY = new JacksonFactory();
private static final String SERVICE_VERSION = "GData-Java/"
		+ Service.class.getPackage().getImplementationVersion() + "(gzip)";
private static GDataRequestFactory REQUEST_FACTORY = null;
private static GoogleAuthTokenFactory TOKEN_FACTORY = null;
// Define the URL to request. This should never change.
private static URL SPREADSHEET_FEED_URL = null;


private static boolean initialized = false;

private static void initialize (ServletContext context) throws Exception {

	if (!initialized) {
		final List<String> scopes = new ArrayList<String>();
		scopes.add("https://spreadsheets.google.com/feeds");

		final GoogleCredential credential = new GoogleCredential.Builder()
		.setTransport(HTTP_TRANSPORT)
		.setJsonFactory(JSON_FACTORY)
		.setServiceAccountId(
				"122803620176-ermsmjc2deibq58360jqs335ace5fmcv@developer.gserviceaccount.com")
		.setServiceAccountPrivateKeyFromP12File(
				new File(
						context.getRealPath("/WEB-INF/privatekey.p12")))
		.setServiceAccountScopes(scopes).build();
		
		SPREADSHEET_FEED_URL = new URL(
				"https://spreadsheets.google.com/feeds/spreadsheets/private/full");
		REQUEST_FACTORY = new GoogleGDataRequest.Factory();
		TOKEN_FACTORY = new GoogleAuthTokenFactory(
				"wise", "rkanadam-test", "https", "www.google.com", null);
		TOKEN_FACTORY.setOAuth2Credentials(credential);

		REQUEST_FACTORY.setAuthToken(TOKEN_FACTORY.getAuthToken());
		initialized = true;
	}
}

private static GDataRequest get (final URL url) throws Exception {
	
	int numTimes = 0;
	do {
        try {
        	final GDataRequest request = REQUEST_FACTORY.getRequest(RequestType.QUERY,
		    	url, ContentType.ATOM);
            request.execute();
			return request;
        } catch (final SessionExpiredException e) {
            TOKEN_FACTORY.handleSessionExpiredException(e);
        } catch (java.net.SocketException e) {
            //Connection reset continue as planned
        }
     } while (++numTimes < 10);
	 throw new Exception ("Could not complete request processing");
}

private static GDataRequest insert (final URL url, final String data) throws Exception {
	int numTimes = 0;
	do {
        try {
        	final GDataRequest request = REQUEST_FACTORY.getRequest(RequestType.INSERT,
			url, ContentType.ATOM);
			request.getRequestStream().write(data.getBytes());
            request.execute();
			return request;
        } catch (final SessionExpiredException e) {
            TOKEN_FACTORY.handleSessionExpiredException(e);
        } catch (java.net.SocketException e) {
            //Connection reset continue as planned
        }
     } while (++numTimes < 10);
	 throw new Exception ("Could not complete request processing");
}

private static GDataRequest update (final URL url, final String data) throws Exception {
	
	int numTimes = 0;
	do {
        try {
        	final GDataRequest request = REQUEST_FACTORY.getRequest(RequestType.UPDATE,
			url, ContentType.ATOM);
			request.getRequestStream().write(data.getBytes());
            request.execute();
			return request;
        } catch (final SessionExpiredException e) {
            TOKEN_FACTORY.handleSessionExpiredException(e);
        } catch (java.net.SocketException e) {
            //Connection reset continue as planned
        }
     } while (++numTimes < 10);
	 throw new Exception ("Could not complete request processing");
}

private static GDataRequest delete (final URL url) throws Exception {
	
	GDataRequest request = REQUEST_FACTORY.getRequest(RequestType.DELETE,
			SPREADSHEET_FEED_URL, ContentType.ATOM);
	try {
		request.execute();
	} catch (final SessionExpiredException e) {
		TOKEN_FACTORY.handleSessionExpiredException(e);
		request = REQUEST_FACTORY.getRequest(RequestType.DELETE,
				url, ContentType.ATOM);
		request.execute();
	}
	
	return request;
}


%>

<%
	response.setHeader("Access-Control-Allow-Origin", "*");
	response.setHeader("Access-Control-Allow-Methods", "*");
	response.setHeader("Access-Control-Allow-Headers", "*");
	response.setContentType("application/xml");

	final String method = request.getMethod();
	
	final String path = StringUtils.trimToNull(request.getPathInfo());
	if (path == null || "/".equals(path)) {
		return; //do nothing keep mum
	}
	//feeds/spreadsheets/private/full
	initialize(getServletContext());
	if ("GET".equalsIgnoreCase(method)) {
		final GDataRequest dataRequest = get(new URL("https://spreadsheets.google.com" + path));
		IOUtils.copy(dataRequest.getResponseStream(), response.getWriter());		
	} else if ("POST".equalsIgnoreCase(method)) {
		final List<String> lines = IOUtils.readLines(request.getInputStream());
		final GDataRequest dataRequest = update(new URL("https://spreadsheets.google.com" + path), StringUtils.join(lines, "\n"));
		IOUtils.copy(dataRequest.getResponseStream(), response.getWriter());		
	} else if ("PUT".equalsIgnoreCase(method)) {
		final List<String> lines = IOUtils.readLines(request.getInputStream());
		final GDataRequest dataRequest = insert(new URL("https://spreadsheets.google.com" + path), StringUtils.join(lines, "\n"));
		IOUtils.copy(dataRequest.getResponseStream(), response.getWriter());		
	} else if ("DELETE".equalsIgnoreCase(method)) {
		final GDataRequest dataRequest = delete(new URL("https://spreadsheets.google.com" + path));
		IOUtils.copy(dataRequest.getResponseStream(), response.getWriter());		
	} 
%>
