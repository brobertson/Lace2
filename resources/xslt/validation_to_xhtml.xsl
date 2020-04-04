<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xhtml="http://www.w3.org/1999/xhtml" version="1.0">

<xsl:template match="/">
<xhtml:div>
<xsl:apply-templates select="//validationreport"/>
</xhtml:div>
</xsl:template>

<xsl:template match="validationreport">
	<xhtml:div>
		<xsl:choose>
			<xsl:when test="report/status='valid'">✅</xsl:when>
			<xsl:otherwise>❌</xsl:otherwise>
		</xsl:choose>
		<xsl:value-of select="@file"/>
	</xhtml:div>
</xsl:template>

</xsl:stylesheet>