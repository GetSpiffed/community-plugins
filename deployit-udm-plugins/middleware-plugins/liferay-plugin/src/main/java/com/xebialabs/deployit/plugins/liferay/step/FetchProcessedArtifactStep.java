package com.xebialabs.deployit.plugins.liferay.step;

import com.google.common.io.Closeables;
import com.xebialabs.deployit.plugin.api.deployment.execution.DeploymentExecutionContext;
import com.xebialabs.deployit.plugin.api.deployment.execution.DeploymentStep;
import com.xebialabs.deployit.plugin.api.flow.ExecutionContext;
import com.xebialabs.deployit.plugin.api.flow.Step;
import com.xebialabs.deployit.plugin.api.flow.StepExitCode;
import com.xebialabs.deployit.plugin.api.udm.artifact.Artifact;
import com.xebialabs.deployit.plugin.overthere.Host;
import com.xebialabs.overthere.OverthereConnection;
import com.xebialabs.overthere.OverthereFile;

import static java.lang.String.format;

public class FetchProcessedArtifactStep implements Step {

	private final int order;
	private final Artifact artifact;
	private final String remoteLocation;
	private final Host host;
	private final boolean fetch;

	public FetchProcessedArtifactStep(int order, Host host, Artifact artifact, String remoteLocation, boolean fetch) {
		this.order = order;
		this.host = host;
		this.artifact = artifact;
		this.remoteLocation = remoteLocation;
		this.fetch = fetch;
	}

	@Override
	public String getDescription() {
		return format("Fetch the processed artifact %s from %s", artifact, host);
	}

    @Override
    public StepExitCode execute(final ExecutionContext executionContext) throws Exception {
        try (OverthereConnection connection = host.getConnection() ) {
            final OverthereFile remoteFile = connection.getFile(remoteLocation);
            if (!remoteFile.exists()) {
                executionContext.logError(format("The remote file does not exist %s", remoteFile));
                return StepExitCode.FAIL;
            }
            if (fetch) {
                final OverthereFile artifactOrginalFile = artifact.getFile();
                executionContext.logOutput(format("Copy the processed file %s back to the deployit server %s", remoteFile, artifactOrginalFile));
                remoteFile.copyTo(artifactOrginalFile);
            } else {
                executionContext.logOutput(format("Change the file property of %s: from %s to %s", artifact.getName(), artifact.getFile(), remoteFile));
                artifact.setFile(remoteFile);
            }

            return StepExitCode.SUCCESS;
        }
    }

    public int getOrder() {
		return order;
	}
}
