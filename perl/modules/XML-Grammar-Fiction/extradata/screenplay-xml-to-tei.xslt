<xsl:stylesheet version = '1.0'
     xmlns:xsl='http://www.w3.org/1999/XSL/Transform'
     xmlns:sp="http://web-cpan.berlios.de/modules/XML-Grammar-Screenplay/screenplay-xml-0.2/"
     >

<xsl:output method="xml" version="1.0" encoding="UTF-8" indent="yes"
 doctype-public="-//W3C//DTD XHTML 1.1//EN"
 doctype-system="http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd"
 />

<xsl:template match="/">
        <xsl:apply-templates select="//sp:body" />  
</xsl:template>

<xsl:template match="sp:body">
    <text>
        <body>
            <div type="act">
                <xsl:attribute name="xml:id">
                    <xsl:value-of select="@id" />
                </xsl:attribute>
                <head>ACT I</head>
                <xsl:apply-templates select="sp:scene" />
            </div>
        </body>
    </text>
</xsl:template>

<xsl:template match="sp:scene">
    <div type="scene" xml:id="scene-{@id}">
        <!-- Make the title the title attribute or "ID" if does not exist. -->
        <head>
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
        </head>
        <xsl:apply-templates select="sp:scene|sp:description|sp:saying" />
    </div>
</xsl:template>

<xsl:template match="sp:description">
    <stage>
        <xsl:apply-templates />
    </stage>
</xsl:template>

<xsl:template match="sp:saying">
    <sp>
        <speaker>
            <xsl:value-of select="@character" />
        </speaker>
        <xsl:apply-templates />
    </sp>
</xsl:template>

<xsl:template match="sp:para">
    <p>
        <xsl:apply-templates />
    </p>
</xsl:template>

<xsl:template match="sp:ulink">
    <a>
        <xsl:attribute name="href">
            <xsl:value-of select="@url" />
        </xsl:attribute>
        <xsl:apply-templates />
    </a>
</xsl:template>

<xsl:template match="sp:bold">
    <strong class="bold">
        <xsl:apply-templates />
    </strong>
</xsl:template>

<xsl:template match="sp:italics">
    <em class="italics">
        <xsl:apply-templates />
    </em>
</xsl:template>

<xsl:template match="sp:inlinedesc">
    <span class="inlinedesc">[<xsl:apply-templates />]</span>
</xsl:template>

<xsl:template match="sp:br">
    <br />
</xsl:template>

</xsl:stylesheet>
