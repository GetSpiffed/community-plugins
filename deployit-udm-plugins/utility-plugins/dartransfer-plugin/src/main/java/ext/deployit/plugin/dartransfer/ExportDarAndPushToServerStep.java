package ext.deployit.plugin.dartransfer;

import java.io.File;

import org.apache.http.HttpEntity;
import org.apache.http.auth.AuthScope;
import org.apache.http.auth.UsernamePasswordCredentials;
import org.apache.http.client.CredentialsProvider;
import org.apache.http.client.methods.CloseableHttpResponse;
import org.apache.http.client.methods.HttpPost;
import org.apache.http.entity.ContentType;
import org.apache.http.entity.mime.MultipartEntityBuilder;
import org.apache.http.entity.mime.content.FileBody;
import org.apache.http.impl.client.BasicCredentialsProvider;
import org.apache.http.impl.client.CloseableHttpClient;
import org.apache.http.impl.client.HttpClients;
import org.apache.http.util.EntityUtils;

import com.xebialabs.deployit.plugin.api.flow.ExecutionContext;
import com.xebialabs.deployit.plugin.api.flow.Step;
import com.xebialabs.deployit.plugin.api.flow.StepExitCode;
import com.xebialabs.deployit.plugin.api.udm.Deployed;
import com.xebialabs.deployit.repository.RepositoryService;
import com.xebialabs.deployit.repository.RepositoryServiceHolder;
import com.xebialabs.deployit.repository.WorkDir;
import com.xebialabs.deployit.service.version.exporter.ExporterService;
import com.xebialabs.overthere.OverthereConnection;
import com.xebialabs.overthere.OverthereFile;
import com.xebialabs.overthere.local.LocalConnection;
import com.xebialabs.overthere.local.LocalFile;

@SuppressWarnings("serial")
public class ExportDarAndPushToServerStep implements Step {
	
	private Deployed<?, ?> projectBundle;

	public ExportDarAndPushToServerStep(Deployed<?, ?> projectBundle) {
		this.projectBundle = projectBundle;
	}

	public int getOrder() {
		return 50;
	}
	public String getDescription() {
		String address = projectBundle.getContainer().getProperty("serverAddress");
		String port = projectBundle.getContainer().getProperty("serverPort").toString();
		return "Transfer deployment package to XL Deploy server [" + address + ":" + port + "]";
	}
	
	public StepExitCode execute(ExecutionContext ctx) throws Exception {
		String bundleId = projectBundle.getDeployable().getId();
		String packageId = getParentId(bundleId);

		//String version = packageId.substring(packageId.lastIndexOf("/")+1, packageId.length());
		//projectBundle.setId(projectBundle.getId()+"-"+version);	
				
		OverthereConnection localConnection = null;
		File createdTmpDir = null;
		try {
			//Export the package dar
            ctx.logOutput("Exporting: " + packageId);
			localConnection = (LocalConnection) LocalConnection.getLocalConnection();
			RepositoryService repositoryService = RepositoryServiceHolder.getRepositoryService();
			ExporterService exportService = new ExporterService(repositoryService);

			OverthereFile workingDirectory = localConnection.getWorkingDirectory();
			if (workingDirectory == null) {
				createdTmpDir = createTmpDir(localConnection);
				workingDirectory = new LocalFile((LocalConnection) localConnection, createdTmpDir);
				localConnection.setWorkingDirectory(workingDirectory);
			}
			WorkDir workDir = new WorkDir((LocalFile) workingDirectory);
			LocalFile exportedDar = exportService.exportDar(packageId, workDir);
            ctx.logOutput("Completed export to file: " + exportedDar.getFile().getName());
			//exportedDar.copyTo(workingDirectory);
			
			//Connect to XL Deploy instance
			String server = 	projectBundle.getContainer().getProperty("serverAddress");
			int port = 			projectBundle.getContainer().getProperty("serverPort");
			String username = 	projectBundle.getContainer().getProperty("username");
			String password = 	projectBundle.getContainer().getProperty("password");

	        CloseableHttpClient httpclient = null;
	        try {
	        	CredentialsProvider credsProvider = new BasicCredentialsProvider();
	        	credsProvider.setCredentials(
	                new AuthScope(server, port),
	                new UsernamePasswordCredentials(username, password));
	        	httpclient = HttpClients.custom()
	                .setDefaultCredentialsProvider(credsProvider)
	                .build();
	            HttpPost httppost = new HttpPost("http://" + server + ":" + port +
	                    "/deployit/package/upload/file:Package.dar");
	            File darFile = exportedDar.getFile();
	            
	            ctx.logOutput("Uploading file: " + darFile.getAbsolutePath());

	            FileBody bin = new FileBody(darFile, ContentType.MULTIPART_FORM_DATA);
	            
	            HttpEntity reqEntity = MultipartEntityBuilder.create()
	                    .addPart("fileData", bin)
	                    .build();
	            
	            httppost.setEntity(reqEntity);

	            ctx.logOutput("Executing request " + httppost.getRequestLine());
	            CloseableHttpResponse response = httpclient.execute(httppost);
	            try {
	                ctx.logOutput("----------------------------------------");
	                ctx.logOutput(response.getStatusLine().toString());
	                HttpEntity resEntity = response.getEntity();
	                if (resEntity != null) {
	                    ctx.logOutput("Response content length: " + resEntity.getContentLength());
	                }
	                if(!response.getStatusLine().getReasonPhrase().equals("OK")) {
	        			ctx.logError("DAR transfer was unsuccessful");
	                    return StepExitCode.FAIL;                	
	                }
	                EntityUtils.consume(resEntity);
	            } finally {
	                response.close();
	            }
	        } finally {
	            httpclient.close();
	        }
			
		} catch (Exception e) {
			ctx.logError("Caught exception in uploading DAR to server.", e);
            return StepExitCode.FAIL;
		} finally {
			removeTmpDir(createdTmpDir);
		}
        ctx.logOutput("DAR transfer completed successfully");
		return StepExitCode.SUCCESS;
	}

	private String getParentId(String id) {
		return id.substring(0, id.lastIndexOf("/"));
	}
	
	private File createTmpDir(OverthereConnection localConnection) {
		String property = "java.io.tmpdir";
		String tempDir = System.getProperty(property);
		String pathSeparator = localConnection.getHostOperatingSystem()
				.getFileSeparator();
		String workDir = tempDir + pathSeparator + "work"
				+ System.currentTimeMillis();
		File workDirAsFile = new File(workDir);
		workDirAsFile.mkdir();
		return workDirAsFile;
	}

	private void removeTmpDir(File createdTmpDir) {
		if (createdTmpDir != null) {
			if (createdTmpDir.isFile()) {
				createdTmpDir.delete();
			} else if (createdTmpDir.isDirectory()) {
				File[] files = createdTmpDir.listFiles();
				if (files != null) {
					for (File file : files) {
						removeTmpDir(file);
					}
				}
				createdTmpDir.delete();
			}
		}
	}

}
