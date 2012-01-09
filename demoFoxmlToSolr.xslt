<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0"
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	xmlns:exts="xalan://dk.defxws.fedoragsearch.server.GenericOperationsImpl"
	xmlns:zs="http://www.loc.gov/zing/srw/" xmlns:foxml="info:fedora/fedora-system:def/foxml#"
	xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:oai_dc="http://www.openarchives.org/OAI/2.0/oai_dc/"
	xmlns:tei="http://www.tei-c.org/ns/1.0" xmlns:mods="http://www.loc.gov/mods/v3"
	xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#" xmlns:rdfs="http://www.w3.org/2000/01/rdf-schema#"
	xmlns:fedora="info:fedora/fedora-system:def/relations-external#"
	xmlns:rel="info:fedora/fedora-system:def/relations-external#"
	xmlns:dwc="http://rs.tdwg.org/dwc/xsd/simpledarwincore/"
	xmlns:fedora-model="info:fedora/fedora-system:def/model#"
	xmlns:uvalibdesc="http://dl.lib.virginia.edu/bin/dtd/descmeta/descmeta.dtd"
	xmlns:pb="http://www.pbcore.org/PBCore/PBCoreNamespace.html"
	xmlns:uvalibadmin="http://dl.lib.virginia.edu/bin/admin/admin.dtd/">
	<xsl:output method="xml" indent="yes" encoding="UTF-8" />

	<!-- This xslt stylesheet generates the Solr doc element consisting of field 
		elements from a FOXML record. The PID field is mandatory. Options for tailoring: 
		- generation of fields from other XML metadata streams than DC - generation 
		of fields from other datastream types than XML - from datastream by ID, text 
		fetched, if mimetype can be handled currently the mimetypes text/plain, text/xml, 
		text/html, application/pdf can be handled. -->

	<xsl:param name="REPOSITORYNAME" select="repositoryName" />
	<xsl:param name="FEDORASOAP" select="repositoryName" />
	<xsl:param name="FEDORAUSER" select="repositoryName" />
	<xsl:param name="FEDORAPASS" select="repositoryName" />
	<xsl:param name="TRUSTSTOREPATH" select="repositoryName" />
	<xsl:param name="TRUSTSTOREPASS" select="repositoryName" />
	<xsl:variable name="PID" select="/foxml:digitalObject/@PID" />
	<xsl:variable name="docBoost" select="1.4*2.5" />
	<!-- or any other calculation, default boost is 1.0 -->

	<xsl:template match="/">
		<add>
			<doc>
				<xsl:attribute name="boost">
                    <xsl:value-of select="$docBoost" />
                </xsl:attribute>
				<!-- The following allows only active demo FedoraObjects to be indexed. -->
				<xsl:if
					test="foxml:digitalObject/foxml:objectProperties/foxml:property[@NAME='info:fedora/fedora-system:def/model#state' and @VALUE='Active']">
					<xsl:if
						test="not(foxml:digitalObject/foxml:datastream[@ID='METHODMAP'] or foxml:digitalObject/foxml:datastream[@ID='DS-COMPOSITE-MODEL'])">
						<xsl:if test="starts-with($PID,'')">
							<xsl:apply-templates mode="activeDemoFedoraObject" />
						</xsl:if>
					</xsl:if>
				</xsl:if>
			</doc>
		</add>
	</xsl:template>

	<xsl:template match="/foxml:digitalObject" mode="activeDemoFedoraObject">
		<field name="PID" boost="2.5">
			<xsl:value-of select="$PID" />
		</field>
		<xsl:for-each select="foxml:objectProperties/foxml:property">
			<field>
				<xsl:attribute name="name">
                    <xsl:value-of
					select="concat('fgs.', substring-after(@NAME,'#'))" />
                </xsl:attribute>
				<xsl:value-of select="@VALUE" />
			</field>
		</xsl:for-each>
		<xsl:for-each
			select="foxml:datastream/foxml:datastreamVersion[last()]/foxml:xmlContent/oai_dc:dc/*">
			<xsl:if test="text() [normalize-space(.) ]">
				
				<field>
					<xsl:attribute name="name">
                        <xsl:value-of
						select="concat('dc.', substring-after(name(),':'))" />
                    </xsl:attribute>
					<xsl:value-of select="normalize-space(text())" />
				</field>
			</xsl:if>
		</xsl:for-each>
		<xsl:for-each
			select="foxml:datastream/foxml:datastreamVersion[last()]/foxml:xmlContent/reference/*">
			<field>
				<xsl:attribute name="name">
                    <xsl:value-of select="concat('refworks.', name())" />
                </xsl:attribute>
				<xsl:value-of select="text()" />
			</field>
		</xsl:for-each>


		<xsl:for-each
			select="foxml:datastream[@ID='RIGHTSMETADATA']/foxml:datastreamVersion[last()]/foxml:xmlContent//access/human/person">
			<field>
				<xsl:attribute name="name">access.person</xsl:attribute>
				<xsl:value-of select="text()" />
			</field>
		</xsl:for-each>
		<xsl:for-each
			select="foxml:datastream[@ID='RIGHTSMETADATA']/foxml:datastreamVersion[last()]/foxml:xmlContent//access/human/group">
			<field>
				<xsl:attribute name="name">access.group</xsl:attribute>
				<xsl:value-of select="text()" />
			</field>
		</xsl:for-each>

		<xsl:for-each
			select="foxml:datastream[@ID='TAGS']/foxml:datastreamVersion[last()]/foxml:xmlContent//tag">
			<!--<xsl:for-each select="foxml:datastream/foxml:datastreamVersion[last()]/foxml:xmlContent//tag"> -->
			<field>
				<xsl:attribute name="name">tag</xsl:attribute>
				<xsl:value-of select="text()" />
			</field>
			<field>
				<xsl:attribute name="name">tagUser</xsl:attribute>
				<xsl:value-of select="@creator" />
			</field>
		</xsl:for-each>

		<xsl:for-each
			select="foxml:datastream[@ID='RELS-EXT']/foxml:datastreamVersion[last()]/foxml:xmlContent//rdf:description/*">
			<field>
				<xsl:attribute name="name">
                    <xsl:value-of
					select="concat('rels.', substring-after(name(),':'))" />
                </xsl:attribute>
				<xsl:value-of select="@rdf:resource" />
			</field>
		</xsl:for-each>




		<!--***********************************************************end full 
			text******************************************************************************** -->


		<!--********************************************Darwin Core********************************************************************** -->

		<xsl:for-each
			select="foxml:datastream/foxml:datastreamVersion[last()]/foxml:xmlContent/dwc:SimpleDarwinRecordSet/dwc:SimpleDarwinRecord/*">
			<xsl:if test="text() [normalize-space(.) ]">
				
				<field>
					<xsl:attribute name="name">
                        <xsl:value-of
						select="concat('dwc.', substring-after(name(),':'))" />
                    </xsl:attribute>
					<xsl:value-of select="normalize-space(text())" />
				</field>
			</xsl:if>
		</xsl:for-each>




		<!--*********************************************END Darwin Core***************************************************************** -->






		<!-- a managed datastream is fetched, if its mimetype can be handled, the 
			text becomes the value of the field. -->
		<!--<xsl:for-each select="foxml:datastream[@CONTROL_GROUP='M']"> <field> 
			<xsl:attribute name="name"> <xsl:value-of select="concat('dsm.', @ID)"/> 
			</xsl:attribute> <xsl:value-of select="exts:getDatastreamText($PID, $REPOSITORYNAME, 
			@ID, $FEDORASOAP, $FEDORAUSER, $FEDORAPASS, $TRUSTSTOREPATH, $TRUSTSTOREPASS)"/> 
			</field> </xsl:for-each> -->



		<!--*********************************** begin changes for Mods as a managed 
			datastream users an islandor extension function used by MAPS, BOOKS etc******************************************************************************** -->
		<!-- call the tei template -->
    <xsl:call-template name="MODS" />

		<!-- call the tei template -->
		<xsl:call-template name="tei" />

	</xsl:template>

	<xsl:template name="MODS">
		<!--***********************************************************MODS modified 
			for maps********************************************************************************** -->
		<field>
			<xsl:attribute name="name">
                <xsl:value-of select="concat('mods.', 'indexTitle')" />
            </xsl:attribute>
			<xsl:value-of select="foxml:datastream[@ID='MODS']/foxml:datastreamVersion[last()]/foxml:xmlContent//mods:title" />
		</field>

		<xsl:for-each select="foxml:datastream[@ID='MODS']/foxml:datastreamVersion[last()]/foxml:xmlContent//mods:title">
			<xsl:if test="text() [normalize-space(.) ]">
				
				<field>
					<xsl:attribute name="name">
                        <xsl:value-of select="concat('mods.', 'title')" />
                    </xsl:attribute>
					<xsl:value-of select="../mods:nonSort/text()" />
					<xsl:text> </xsl:text>
					<xsl:value-of select="text()" />
				</field>
			</xsl:if>

		</xsl:for-each>
		<xsl:for-each select="foxml:datastream[@ID='MODS']/foxml:datastreamVersion[last()]/foxml:xmlContent//mods:subTitle">
			<xsl:if test="text() [normalize-space(.) ]">
				
				<field>
					<xsl:attribute name="name">
                        <xsl:value-of select="concat('mods.', 'subTitle')" />
                    </xsl:attribute>
					<xsl:value-of select="normalize-space(text())" />
				</field>
			</xsl:if>

		</xsl:for-each>
		<xsl:for-each select="foxml:datastream[@ID='MODS']/foxml:datastreamVersion[last()]/foxml:xmlContent//mods:abstract">
			<xsl:if test="text() [normalize-space(.) ]">
				
				<field>
					<xsl:attribute name="name">
                        <xsl:value-of select="concat('mods.', name())" />
                    </xsl:attribute>
					<xsl:value-of select="text()" />
				</field>
			</xsl:if>


		</xsl:for-each>
		<!--test of optimized version don't call normalize-space twice in this 
			one -->
		<xsl:for-each select="foxml:datastream[@ID='MODS']/foxml:datastreamVersion[last()]/foxml:xmlContent//mods:genre">
			<xsl:variable name="textValue" select="normalize-space(text())" />
			<xsl:if test="$textValue != ''">
				<field>
					<xsl:attribute name="name">
                        <xsl:value-of select="concat('mods.', name())" />
                    </xsl:attribute>
					<xsl:value-of select="$textValue" />
				</field>
			</xsl:if>


		</xsl:for-each>
		<xsl:for-each select="foxml:datastream[@ID='MODS']/foxml:datastreamVersion[last()]/foxml:xmlContent//mods:form">
			<xsl:if test="text() [normalize-space(.) ]">
				
				<field>
					<xsl:attribute name="name">
                        <xsl:value-of select="concat('mods.', name())" />
                    </xsl:attribute>
					<xsl:value-of select="normalize-space(text())" />
				</field>
			</xsl:if>


		</xsl:for-each>
		<xsl:for-each select="foxml:datastream[@ID='MODS']/foxml:datastreamVersion[last()]/foxml:xmlContent//mods:roleTerm">
			<xsl:if test="text() [normalize-space(.) ]">
				
				<field>
					<xsl:attribute name="name">
                        <xsl:value-of select="concat('mods.', text())" />
                    </xsl:attribute>
					<xsl:value-of select="../../mods:namePart/text()" />
				</field>
			</xsl:if>

		</xsl:for-each>

		<xsl:for-each
			select="foxml:datastream[@ID='MODS']/foxml:datastreamVersion[last()]/foxml:xmlContent//mods:note[@type='statement of responsibility']">
			<xsl:if test="text() [normalize-space(.) ]">
				
				<field>
					<xsl:attribute name="name">
                        <xsl:value-of select="concat('mods.', 'sor')" />
                    </xsl:attribute>
					<xsl:value-of select="normalize-space(text())" />
				</field>
			</xsl:if>

		</xsl:for-each>
		<xsl:for-each select="foxml:datastream[@ID='MODS']/foxml:datastreamVersion[last()]/foxml:xmlContent//mods:note">
			<xsl:if test="text() [normalize-space(.) ]">
				
				<field>
					<xsl:attribute name="name">
                        <xsl:value-of select="concat('mods.', 'note')" />
                    </xsl:attribute>
					<xsl:value-of select="normalize-space(text())" />
				</field>
			</xsl:if>

		</xsl:for-each>

		<xsl:for-each select="foxml:datastream[@ID='MODS']/foxml:datastreamVersion[last()]/foxml:xmlContent//mods:topic">
			<xsl:if test="text() [normalize-space(.) ]">
				
				<field>
					<xsl:attribute name="name">
                        <xsl:value-of select="concat('mods.', 'topic')" />
                    </xsl:attribute>
					<xsl:value-of select="normalize-space(text())" />
				</field>
			</xsl:if>

		</xsl:for-each>

		<xsl:for-each select="foxml:datastream[@ID='MODS']/foxml:datastreamVersion[last()]/foxml:xmlContent//mods:geographic">
			<xsl:if test="text() [normalize-space(.) ]">
				
				<field>
					<xsl:attribute name="name">
                        <xsl:value-of select="concat('mods.', 'geographic')" />
                    </xsl:attribute>
					<xsl:value-of select="normalize-space(text())" />
				</field>
			</xsl:if>

		</xsl:for-each>

		<xsl:for-each select="foxml:datastream[@ID='MODS']/foxml:datastreamVersion[last()]/foxml:xmlContent//mods:caption">
			<xsl:if test="text() [normalize-space(.) ]">
				
				<field>
					<xsl:attribute name="name">
                        <xsl:value-of select="concat('mods.', 'caption')" />
                    </xsl:attribute>
					<xsl:value-of select="normalize-space(text())" />
				</field>
			</xsl:if>

		</xsl:for-each>


		<xsl:for-each select="foxml:datastream[@ID='MODS']/foxml:datastreamVersion[last()]/foxml:xmlContent//mods:subject/*">
			<xsl:if test="text() [normalize-space(.) ]">
				
				<field>
					<xsl:attribute name="name">
                        <!--changed names to have each child element uniquely indexed-->
                        <xsl:value-of select="concat('mods.', 'subject')" />
                    </xsl:attribute>
					<xsl:value-of select="normalize-space(text())" />
				</field>
			</xsl:if>

		</xsl:for-each>

		<xsl:for-each select="foxml:datastream[@ID='MODS']/foxml:datastreamVersion[last()]/foxml:xmlContent//mods:extent">
			<xsl:if test="text() [normalize-space(.) ]">
				
				<field>
					<xsl:attribute name="name">
                        <xsl:value-of select="concat('mods.', 'extent')" />
                    </xsl:attribute>
					<xsl:value-of select="normalize-space(text())" />
				</field>
			</xsl:if>
		</xsl:for-each>

		<xsl:for-each select="foxml:datastream[@ID='MODS']/foxml:datastreamVersion[last()]/foxml:xmlContent//mods:accessCondition">
			<xsl:if test="text() [normalize-space(.) ]">
				
				<field>
					<xsl:attribute name="name">
                        <xsl:value-of
						select="concat('mods.', 'accessCondition')" />
                    </xsl:attribute>
					<xsl:value-of select="normalize-space(text())" />
				</field>
			</xsl:if>
		</xsl:for-each>

		<xsl:for-each select="foxml:datastream[@ID='MODS']/foxml:datastreamVersion[last()]/foxml:xmlContent//mods:country">
			<xsl:if test="text() [normalize-space(.) ]">
				
				<field>
					<xsl:attribute name="name">
                        <xsl:value-of select="concat('mods.', 'country')" />
                    </xsl:attribute>
					<xsl:value-of select="normalize-space(text())" />
				</field>
			</xsl:if>
		</xsl:for-each>
		<xsl:for-each select="foxml:datastream[@ID='MODS']/foxml:datastreamVersion[last()]/foxml:xmlContent//mods:province">
			<xsl:if test="text() [normalize-space(.) ]">
				
				<field>
					<xsl:attribute name="name">
                        <xsl:value-of select="concat('mods.', 'province')" />
                    </xsl:attribute>
					<xsl:value-of select="normalize-space(text())" />
				</field>
			</xsl:if>
		</xsl:for-each>
		<xsl:for-each select="foxml:datastream[@ID='MODS']/foxml:datastreamVersion[last()]/foxml:xmlContent//mods:county">
			<xsl:if test="text() [normalize-space(.) ]">
				
				<field>
					<xsl:attribute name="name">
                        <xsl:value-of select="concat('mods.', 'county')" />
                    </xsl:attribute>
					<xsl:value-of select="normalize-space(text())" />
				</field>
			</xsl:if>
		</xsl:for-each>
		<xsl:for-each select="foxml:datastream[@ID='MODS']/foxml:datastreamVersion[last()]/foxml:xmlContent//mods:region">
			<xsl:if test="text() [normalize-space(.) ]">
				
				<field>
					<xsl:attribute name="name">
                        <xsl:value-of select="concat('mods.', 'region')" />
                    </xsl:attribute>
					<xsl:value-of select="normalize-space(text())" />
				</field>
			</xsl:if>
		</xsl:for-each>
		<xsl:for-each select="foxml:datastream[@ID='MODS']/foxml:datastreamVersion[last()]/foxml:xmlContent//mods:city">
			<xsl:if test="text() [normalize-space(.) ]">
				
				<field>
					<xsl:attribute name="name">
                        <xsl:value-of select="concat('mods.', 'city')" />
                    </xsl:attribute>
					<xsl:value-of select="normalize-space(text())" />
				</field>
			</xsl:if>
		</xsl:for-each>
		<xsl:for-each select="foxml:datastream[@ID='MODS']/foxml:datastreamVersion[last()]/foxml:xmlContent//mods:citySection">
			<xsl:if test="text() [normalize-space(.) ]">
				
				<field>
					<xsl:attribute name="name">
                        <xsl:value-of select="concat('mods.', 'citySection')" />
                    </xsl:attribute>
					<xsl:value-of select="normalize-space(text())" />
				</field>
			</xsl:if>
		</xsl:for-each>
		<xsl:for-each
			select="foxml:datastream[@ID='MODS']/foxml:datastreamVersion[last()]/foxml:xmlContent//mods:originInfo//mods:placeTerm[@type='text']">
			<xsl:if test="text() [normalize-space(.) ]">
				
				<field>
					<xsl:attribute name="name">
                        <xsl:value-of
						select="concat('mods.', 'place_of_publication')" />
                    </xsl:attribute>
					<xsl:value-of select="normalize-space(text())" />
				</field>
			</xsl:if>
		</xsl:for-each>

		<xsl:for-each select="foxml:datastream[@ID='MODS']/foxml:datastreamVersion[last()]/foxml:xmlContent//mods:originInfo/mods:publisher">
			<xsl:if test="text() [normalize-space(.) ]">
				
				<field>
					<xsl:attribute name="name">
                        <xsl:value-of select="concat('mods.', name())" />
                    </xsl:attribute>
					<xsl:value-of select="normalize-space(text())" />
				</field>
			</xsl:if>

		</xsl:for-each>
		<xsl:for-each select="foxml:datastream[@ID='MODS']/foxml:datastreamVersion[last()]/foxml:xmlContent//mods:originInfo/mods:edition">
			<xsl:if test="text() [normalize-space(.) ]">
				
				<field>
					<xsl:attribute name="name">
                        <xsl:value-of select="concat('mods.', name())" />
                    </xsl:attribute>
					<xsl:value-of select="normalize-space(text())" />
				</field>
			</xsl:if>

		</xsl:for-each>

		<xsl:for-each select="foxml:datastream[@ID='MODS']/foxml:datastreamVersion[last()]/foxml:xmlContent//mods:originInfo/mods:dateIssued">
			<xsl:if test="text() [normalize-space(.) ]">
				
				<field>
					<xsl:attribute name="name">
                        <xsl:value-of select="concat('mods.', name())" />
                    </xsl:attribute>
					<xsl:value-of select="normalize-space(text())" />
				</field>
			</xsl:if>
		</xsl:for-each>

		<xsl:for-each select="foxml:datastream[@ID='MODS']/foxml:datastreamVersion[last()]/foxml:xmlContent//mods:originInfo/mods:dateCreated">
			<xsl:if test="text() [normalize-space(.) ]">
				
				<field>
					<xsl:attribute name="name">
                        <xsl:value-of select="concat('mods.', name())" />
                    </xsl:attribute>
					<xsl:value-of select="normalize-space(text())" />
				</field>
			</xsl:if>
		</xsl:for-each>
	</xsl:template>

	<xsl:template name="tei">

		<xsl:variable name="PROT">http</xsl:variable>
		<xsl:variable name="FEDORAUSERNAME">fedoraAdmin</xsl:variable>
		<xsl:variable name="FEDORAPASSWORD">nothingtoseeheremovealong</xsl:variable>
		<xsl:variable name="HOST">dora.hpc.hamilton.edu</xsl:variable>
		<xsl:variable name="PORT">8080</xsl:variable>
		<xsl:variable name="TEI"
			select="document(concat($PROT, '://', $FEDORAUSERNAME, ':', $FEDORAPASSWORD, '@', $HOST, ':', $PORT, '/fedora/objects/', $PID, '/datastreams/', 'TEI', '/content'))" />

		<!-- surname -->
		<xsl:for-each select="$TEI//tei:surname[text()]">
			<field>
				<xsl:attribute name="name">
            <xsl:value-of select="concat('tei_', 'surname_s')" />
            </xsl:attribute>
				<xsl:value-of select="normalize-space(text())" />
			</field>
		</xsl:for-each>

		<!-- place name -->
		<xsl:for-each select="$TEI//tei:placeName/*[text()]">
			<field>
				<xsl:attribute name="name">
            <xsl:value-of select="concat('tei_', 'placeName_s')" />
          </xsl:attribute>
				<xsl:value-of select="normalize-space(text())" />
			</field>
		</xsl:for-each>


		<!-- organization name -->
		<xsl:for-each select="$TEI//tei:orgName[text()]">
			<field>
				<xsl:attribute name="name">
          <xsl:value-of select="concat('tei_', 'orgName_s')" />
        </xsl:attribute>
				<xsl:value-of select="normalize-space(text())" />
			</field>
		</xsl:for-each>

	</xsl:template>
</xsl:stylesheet>