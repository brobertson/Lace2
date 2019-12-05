<?xml version="1.0"?>
<xsl:stylesheet xmlns:lace="http://heml.mta.ca/2019/lace" xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">
  <xsl:output method="xml"/>
  <xsl:param name="identifier"></xsl:param>
  <xsl:template match="texts">
	  <xsl:apply-templates select="archivetext[archive_number/text() = $identifier]"/>
  </xsl:template>

  <xsl:template match="archivetext">
    <lace:imagecollection>
      <dc:identifier>
        <xsl:value-of select="archive_number"/>
      </dc:identifier>
      <dc:creator>
        <xsl:value-of select="creator"/>
      </dc:creator>
      <dc:publisher>
        <xsl:value-of select="publisher"/>
      </dc:publisher>
      <dc:date>
        <xsl:value-of select="date"/>
      </dc:date>
      <dc:title>
        <xsl:value-of select="title"/>
        <xsl:value-of select="volume"/>
      </dc:title>
    </lace:imagecollection>
  </xsl:template>
</xsl:stylesheet>
