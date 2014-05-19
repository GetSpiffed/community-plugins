<#if deployed.certificate??>
echo "Removing ${deployed.name} under alias ${deployed.alias} from ${deployed.container.keystore}"
${deployed.container.jvmPath}/bin/keytool -delete -keystore ${deployed.container.keystore} -storepass ${deployed.container.passphrase} -alias ${deployed.alias} -noprompt
<#else>
echo "Empty certificate for ${deployed.name}, the keystore will not be modified"
</#if>