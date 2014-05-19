<#if deployed.certificate??>
-----BEGIN CERTIFICATE-----
${statics["com.google.common.base.Joiner"].on("\n").join(
  statics["com.google.common.base.Splitter"].fixedLength(64).split(deployed.certificate))}
-----END CERTIFICATE-----
</#if>