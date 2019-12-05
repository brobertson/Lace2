<?xml version="1.0"?>
<xsl:stylesheet xmlns:pkg="http://expath.org/ns/pkg" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">
  <xsl:output method="xml"/>
  <xsl:param name="identifier"/>
  <xsl:param name="rundate"/>
  <xsl:template match="texts">
    <xsl:apply-templates select="archivetext[archive_number/text() = $identifier]"/>
  </xsl:template>
  <xsl:template match="archivetext">
    <pkg:package version="1" spec="1.0">
	    <xsl:attribute name="name">http://heml.mta.ca/Lace/Texts/<xsl:value-of select="archive_number"/>/<xsl:value-of select="$rundate"/></xsl:attribute>
      <xsl:attribute name="abbrev">
	      <xsl:value-of select="archive_number"/>_<xsl:value-of select="$rundate"/>
      </xsl:attribute>
      <pkg:title><xsl:value-of select="archive_number"/>: OCR output on <xsl:value-of select="$rundate"/></pkg:title>
      <pkg:dependency>
	      <xsl:attribute name="package">http://heml.mta.ca/Lace/Images/<xsl:value-of select="$identifier"/></xsl:attribute>
      </pkg:dependency>
    </pkg:package>
  </xsl:template>
</xsl:stylesheet>
