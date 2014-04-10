package ext.deployit.plugin.dartransfer;

import com.xebialabs.deployit.plugin.api.flow.ExecutionContext;
import com.xebialabs.deployit.plugin.api.inspection.InspectionContext;
import com.xebialabs.deployit.plugin.api.services.Repository;

public class DummyExecutionContext implements ExecutionContext {

	public void logOutput(String output) {
	}

	public void logError(String error) {
	}

	public void logError(String error, Throwable t) {
	}

	public Object getAttribute(String name) {
		return null;
	}

	public void setAttribute(String name, Object value) {
	}

	public Repository getRepository() {
		return null;
	}

	public InspectionContext getInspectionContext() {
		return null;
	}

}
