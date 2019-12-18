<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xhtml="http://www.w3.org/1999/xhtml" version="1.0">
 <xsl:output method="text" omit-xml-declaration="yes" indent="no"/>
<xsl:template match="html | xhtml:html">
 <xsl:apply-templates select="//span[@class='ocr_line'] | //xhtml:span[@class='ocr_line']"/> 
</xsl:template>
<xsl:template match="span[@class='ocr_line'] | xhtml:span[@class='ocr_line']">
<xsl:apply-templates select="span[@class='ocr_word'] | xhtml:span[@class='ocr_word']"/>
<xsl:text>
</xsl:text>
</xsl:template>
<xsl:template match="span[@class='ocr_word'] | xhtml:span[@class='ocr_word']">
<xsl:value-of select="."/>
        <xsl:text> </xsl:text>
</xsl:template>
</xsl:stylesheet>