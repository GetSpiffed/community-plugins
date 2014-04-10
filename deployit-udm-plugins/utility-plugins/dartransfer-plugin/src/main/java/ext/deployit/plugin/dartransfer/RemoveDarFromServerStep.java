package ext.deployit.plugin.dartransfer;

import com.xebialabs.deployit.plugin.api.flow.ExecutionContext;
import com.xebialabs.deployit.plugin.api.flow.Step;
import com.xebialabs.deployit.plugin.api.flow.StepExitCode;
import com.xebialabs.deployit.plugin.api.udm.Deployed;

@SuppressWarnings("serial")
public class RemoveDarFromServerStep implements Step {
	private Deployed<?, ?> projectBundle;

	public RemoveDarFromServerStep(Deployed<?, ?> projectBundle) {
		this.projectBundle = projectBundle;
	}

	public int getOrder() {
		return 50;
	}

	public String getDescription() {
		String host = projectBundle.getContainer().getProperty("serverAdress");
		return "Removing dar from " + host;
	}
	
	public StepExitCode execute(ExecutionContext ctx) throws Exception {		
		//Initiate FTP parameters
		String host = projectBundle.getContainer().getProperty("serverAdress");
		ctx.logOutput("Removing dar from " + host);

		return StepExitCode.SUCCESS;
	}
}
