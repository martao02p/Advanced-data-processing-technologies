<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">
    <xsl:output method="xml" encoding="UTF-8" indent="yes"/>

    <xsl:template match="/">
        <PRACOWNICY>
            <xsl:for-each select="/ZESPOLY/ROW/PRACOWNICY/ROW">
                <xsl:sort select="ID_PRAC" data-type="number"/>

                <PRACOWNIK
                        ID_PRAC="{ID_PRAC}"
                        ID_ZESP="{ID_ZESP}"
                        ID_SZEFA="{ID_SZEFA}">
                    <xsl:copy-of select="*[not(self::ID_PRAC or self::ID_ZESP or self::ID_SZEFA)]"/>
                </PRACOWNIK>
            </xsl:for-each>
        </PRACOWNICY>
    </xsl:template>

</xsl:stylesheet>