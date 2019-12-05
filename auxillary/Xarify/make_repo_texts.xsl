<?xml version="1.0"?>
<xsl:stylesheet xmlns:repo="http://exist-db.org/xquery/repo"   xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">
  <xsl:output method="xml"/>
  <xsl:param name="identifier"/>
  <xsl:param name="rundate"/>
  <xsl:template match="texts">
    <xsl:apply-templates select="archivetext[archive_number/text() = $identifier]"/>
  </xsl:template>
  <xsl:template match="archivetext">

    <repo:meta>
	    <repo:description>OCR run on <xsl:value-of select="$rundate"/> of <xsl:value-of select="creator"/> (<xsl:value-of select="date"/>)  <xsl:value-of select="title"/></repo:description>
      <repo:author>Bruce Robertson brobertson@mta.ca</repo:author>
      <repo:website>http://heml.mta.ca/lace</repo:website>
      <repo:status>beta</repo:status>
      <repo:copyright>true</repo:copyright>
      <repo:license>GNU-LGPL</repo:license>
      <!-- "library" is a better repo:type, but in that case, one can't
	   see the package in the package manager -->
      <repo:type>library</repo:type>
      <repo:target>
	      <xsl:value-of select="archive_number"/>_<xsl:value-of select="$rundate"/>
      </repo:target>
      <repo:prepare>pre-install.xql</repo:prepare>
      <repo:permissions user="guest" group="guest" mode="rw-rw-rw-"/>
      <repo:finish>post-install.xql</repo:finish>
    </repo:meta>
  </xsl:template>
</xsl:stylesheet>
