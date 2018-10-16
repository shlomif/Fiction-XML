<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version = '1.0'
     xmlns='http://www.w3.org/1999/xhtml'
     xmlns:xsl='http://www.w3.org/1999/XSL/Transform'
     xmlns:sp="http://web-cpan.berlios.de/modules/XML-Grammar-Screenplay/screenplay-xml-0.2/"
     >

<xsl:output method="xml" version="1.0" encoding="UTF-8" indent="yes"
 />

<xsl:template match="/">
        <xsl:apply-templates select="//sp:body" />
</xsl:template>

<xsl:template match="sp:body">
    <html>
        <xsl:attribute name="xml:lang">
            <xsl:value-of select="@xml:lang|./sp:scene/@xml:lang" />
        </xsl:attribute>
        <head>
            <title>My Screenplay</title>
            <meta charset="utf-8" />
        </head>
        <body>
            <main class="screenplay">
            <xsl:attribute name="id">
                <xsl:value-of select="@id" />
            </xsl:attribute>
            <xsl:apply-templates select="sp:scene" />
            </main>
        </body>
    </html>
</xsl:template>

<xsl:template match="sp:scene">
    <section class="scene" id="scene-{@id}">
        <xsl:if test="@xml:lang">
            <xsl:copy-of select="@xml:lang" />
        </xsl:if>
        <header>
            <!-- Make the title the title attribute or "ID" if does not exist. -->
            <xsl:element name="h{count(ancestor-or-self::sp:scene)}">
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
            </xsl:element>
        </header>
        <xsl:apply-templates select="sp:scene|sp:description|sp:saying" />
    </section>
</xsl:template>

<xsl:template match="sp:description">
    <div class="description">
        <xsl:apply-templates />
    </div>
</xsl:template>

<xsl:template match="sp:saying">
    <div class="saying">
        <xsl:apply-templates />
    </div>
</xsl:template>

<xsl:template match="sp:para">
    <p>
        <xsl:if test="local-name(..) = 'saying'">
            <strong class="sayer"><xsl:value-of select="../@character" />:</strong>
            <xsl:text> </xsl:text>
        </xsl:if>
        <xsl:if test="local-name(..) = 'description' and ../child::sp:para[position()=1] = .">
            [
        </xsl:if>
        <xsl:apply-templates />
        <xsl:if test="local-name(..) = 'description' and ../child::sp:para[position()=last()] = .">
            ]
        </xsl:if>
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

<xsl:template match="sp:image">
    <img class="screenplay_image">
        <xsl:attribute name="src">
            <xsl:value-of select="@url" />
        </xsl:attribute>
        <xsl:attribute name="title">
            <xsl:value-of select="@title" />
        </xsl:attribute>
        <xsl:attribute name="alt">
            <xsl:value-of select="@alt" />
        </xsl:attribute>
    </img>
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
