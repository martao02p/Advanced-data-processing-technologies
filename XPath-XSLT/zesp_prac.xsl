<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">
    <xsl:output method="html" encoding="UTF-8"/>

    <xsl:key name="pracById" match="ZESPOLY/ROW/PRACOWNICY/ROW" use="ID_PRAC"/>

    <xsl:template match="/">
        <html>
            <head>
                <meta charset="UTF-8"/>
                <title>ZESPOŁY</title>
            </head>
            <body>
                <h1>ZESPOŁY:</h1>

                <ol>
                    <xsl:apply-templates select="/ZESPOLY/ROW" mode="lista"/>
                </ol>

                <xsl:apply-templates select="/ZESPOLY/ROW" mode="szczegoly"/>
            </body>
        </html>
    </xsl:template>

    <xsl:template match="ROW" mode="lista">
        <li>
            <a href="#{ID_ZESP}">
                <xsl:value-of select="NAZWA"/>
            </a>
        </li>
    </xsl:template>

    <xsl:template match="ROW" mode="szczegoly">
        <xsl:variable name="liczba" select="count(PRACOWNICY/ROW)"/>

        <h2 id="{ID_ZESP}">
            <xsl:value-of select="NAZWA"/>
        </h2>
        <div>Adres: <xsl:value-of select="ADRES"/></div>

        <xsl:if test="$liczba &gt; 0">
            <table border="1">
                <tr>
                    <th>ID</th>
                    <th>Nazwisko</th>
                    <th>Etat</th>
                    <th>Szef</th>
                    <th>Płaca pod.</th>
                    <th>Płaca dod.</th>
                </tr>

                <xsl:apply-templates select="PRACOWNICY/ROW" mode="prac">
                    <xsl:sort select="NAZWISKO"/>
                </xsl:apply-templates>
            </table>
        </xsl:if>

        <div>Liczba pracowników: <xsl:value-of select="$liczba"/></div>
        <hr/>
    </xsl:template>

    <xsl:template match="PRACOWNICY/ROW" mode="prac">
        <tr>
            <td><xsl:value-of select="ID_PRAC"/></td>
            <td><xsl:value-of select="NAZWISKO"/></td>
            <td><xsl:value-of select="ETAT"/></td>
            <td>
                <xsl:choose>
                    <xsl:when test="ID_SZEFA and string(key('pracById', ID_SZEFA)/NAZWISKO) != ''">
                        <xsl:value-of select="key('pracById', ID_SZEFA)/NAZWISKO"/>
                    </xsl:when>
                    <xsl:otherwise>brak</xsl:otherwise>
                </xsl:choose>
            </td>
            <td><xsl:value-of select="PLACA_POD"/></td>
            <td><xsl:value-of select="PLACA_DOD"/></td>
        </tr>
    </xsl:template>

</xsl:stylesheet>
