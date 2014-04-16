package ext.deployit.community.importer.composite;

import com.google.common.base.Function;
import com.google.common.base.Predicate;
import com.google.common.collect.ImmutableList;
import com.google.common.collect.ImmutableMap;
import com.google.common.collect.Maps;
import com.google.common.io.Closeables;
import com.xebialabs.deployit.plugin.api.udm.DeploymentPackage;
import com.xebialabs.deployit.plugin.api.udm.Version;

import javax.annotation.Nullable;
import java.io.File;
import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.io.IOException;
import java.util.List;
import java.util.Map;
import java.util.Properties;

import static com.google.common.collect.Maps.filterKeys;
import static java.lang.String.format;

public class CompositeApplicationDescriptor {

	private static final Predicate<String> IS_CI_PROPERTTY = new Predicate<String>() {
		@Override
		public boolean apply(@Nullable String key) {
			return key.startsWith("CI-");
		}
	};
	private final Map<String, String> descriptor;

	public CompositeApplicationDescriptor(File source) {
		this.descriptor = loadCompositeApplicationDescriptor(source);
	}

	public String getApplication() {
		if (!descriptor.containsKey("application"))
			throw new RuntimeException("application entry not found in the descriptor");
		return descriptor.get("application");
	}

	public String getVersion() {
		if (!descriptor.containsKey("version"))
			throw new RuntimeException("version entry not found in the descriptor");
		return descriptor.get("version");
	}

	public List<Version> getVersions() {
		final ImmutableList.Builder<Version> builder = ImmutableList.builder();
		for (int i = 1; i < Integer.MAX_VALUE; i++) {
			final DeploymentPackage deploymentPackage = new DeploymentPackageCollector(i).apply(descriptor);
			if (deploymentPackage == null) {
				break;
			}
			builder.add(deploymentPackage);
		}
		return builder.build();
	}

	public Map<String, String> getProperties() {
		final ImmutableMap.Builder<String,String> builder = ImmutableMap.builder();

		for (Map.Entry<String, String> entry : filterKeys(descriptor, IS_CI_PROPERTTY).entrySet()) {
			builder.put(entry.getKey().substring("CI-".length()),entry.getValue());
		}
		return builder.build();
	}

	private static class DeploymentPackageCollector implements Function<Map<String, String>, DeploymentPackage> {

		private static final String PACKAGE_PROPERTY_PREFIX = "package.";
		private final String indexedRulePrefix;

		private DeploymentPackageCollector(int index) {
			indexedRulePrefix = PACKAGE_PROPERTY_PREFIX + index + '.';
		}

		@Override
		public DeploymentPackage apply(Map<String, String> descriptor) {
			final String namekey = format("%sname", indexedRulePrefix);
			final String versionkey = format("%sversion", indexedRulePrefix);
			if (descriptor.containsKey(namekey) && descriptor.containsKey(versionkey)) {
				DeploymentPackage dp = new DeploymentPackage();
				dp.setId(format("Applications/%s/%s", descriptor.get(namekey), descriptor.get(versionkey)));
				return dp;
			}
			return null;
		}
	}

	private Map<String, String> loadCompositeApplicationDescriptor(File source) {
		Properties properties = new Properties();
		try (FileInputStream fileInputStream = new FileInputStream(source) ) {
			properties.load(fileInputStream);
		} catch (FileNotFoundException e) {
			throw new RuntimeException("File not found " + source, e);
		} catch (IOException e) {
			throw new RuntimeException("Cannot load " + source, e);
		}
		return Maps.fromProperties(properties);
	}
}
