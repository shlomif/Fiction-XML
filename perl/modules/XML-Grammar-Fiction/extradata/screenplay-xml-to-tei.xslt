<xsl:stylesheet version = '1.0'
     xmlns:xsl='http://www.w3.org/1999/XSL/Transform'
     xmlns:sp="http://web-cpan.berlios.de/modules/XML-Grammar-Screenplay/screenplay-xml-0.2/"
     xmlns:tei="http://www.tei-c.org/ns/1.0"
     >

<xsl:output method="xml" version="1.0" encoding="UTF-8" indent="yes"
 doctype-public="-//W3C//DTD XHTML 1.1//EN"
 doctype-system="http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd"
 />

<xsl:template match="/">
        <xsl:apply-templates select="//sp:body" />  
</xsl:template>

<xsl:template match="sp:body">
    <tei:text>
        <tei:body>
            <tei:div type="act">
                <xsl:attribute name="xml:id">
                    <xsl:value-of select="@id" />
                </xsl:attribute>
                <tei:head>ACT I</tei:head>
                <xsl:apply-templates select="sp:scene" />
            </tei:div>
        </tei:body>
    </tei:text>
</xsl:template>

<xsl:template match="sp:scene">
    <tei:div type="scene" xml:id="scene-{@id}">
        <!-- Make the title the title attribute or "ID" if does not exist. -->
        <tei:head>
            <xsl:attribute name="id">
                <xsl:value-of select="@id" />
            </xsl:attribute>
            <xsl:choose>
                <xsl:when test="@title">
                    <xsl:value-of select="@title" />
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="@id" />
                </xsl:otherwise>
            </xsl:choose>
        </tei:head>
        <xsl:apply-templates select="sp:scene|sp:description|sp:saying" />
    </tei:div>
</xsl:template>

<xsl:template match="sp:description">
    <tei:stage>
        <xsl:apply-templates />
    </tei:stage>
</xsl:template>

<xsl:template match="sp:saying">
    <tei:sp>
        <tei:speaker>
            <xsl:value-of select="@character" />
        </tei:speaker>
        <xsl:apply-templates />
    </tei:sp>
</xsl:template>

<xsl:template match="sp:para">
    <tei:p>
        <xsl:apply-templates />
    </tei:p>
</xsl:template>

<xsl:template match="sp:ulink">
    <ref>
        <xsl:attribute name="terget">
            <xsl:value-of select="@url" />
        </xsl:attribute>
        <xsl:apply-templates />
    </ref>
</xsl:template>

<xsl:template match="sp:bold">
    <tei:hi rend="bold">
        <xsl:apply-templates />
    </tei:hi>
</xsl:template>

<xsl:template match="sp:italics">
    <tei:hi rend="italic">
        <xsl:apply-templates />
    </tei:hi>
</xsl:template>

<xsl:template match="sp:inlinedesc">
    <tei:stage>[<xsl:apply-templates />]</tei:stage>
</xsl:template>

<xsl:template match="sp:br">
    <lb />
</xsl:template>

</xsl:stylesheet>
