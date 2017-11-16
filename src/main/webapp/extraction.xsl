<?xml version="1.0" encoding="UTF-8"?>
<!--
Copyright (c) 2010-2014, Silvio Peroni <essepuntato@gmail.com>

Permission to use, copy, modify, and/or distribute this software for any
purpose with or without fee is hereby granted, provided that the above
copyright notice and this permission notice appear in all copies.

THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
-->
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema" exclude-result-prefixes="xs xd dc rdfs swrl owl2xml owl xsd swrlb rdf f dcterms"
    xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl" version="2.0"
    xmlns:dc="http://purl.org/dc/elements/1.1/"
    xmlns:rdfs="http://www.w3.org/2000/01/rdf-schema#"
    xmlns:swrl="http://www.w3.org/2003/11/swrl#"
    xmlns:owl2xml="http://www.w3.org/2006/12/owl2-xml#"
    xmlns:owl="http://www.w3.org/2002/07/owl#"
    xmlns:xsd="http://www.w3.org/2001/XMLSchema#"
    xmlns:swrlb="http://www.w3.org/2003/11/swrlb#"
    xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
    xmlns:f="http://www.essepuntato.it/xslt/function"
    xmlns:dcterms="http://purl.org/dc/terms/"
    xmlns="http://www.w3.org/1999/xhtml">
     
    <xsl:include href="swrl-module.xsl" />
    <xsl:include href="common-functions.xsl"/>
    <xsl:include href="structural-reasoner.xsl"/>
    
    <xsl:output encoding="UTF-8" indent="no" method="xhtml" />
    
    <xsl:param name="lang" select="'en'" as="xs:string" />
    <xsl:param name="css-location" select="'./'" as="xs:string" />
    <xsl:param name="source" as="xs:string" select="''" />
    <xsl:param name="ontology-url" as="xs:string" select="''" />
    
    <xsl:variable name="def-lang" select="'en'" as="xs:string" />
    <xsl:variable name="n" select="'\n|\r|\r\n'" />
    <xsl:variable name="rdf" select="/rdf:RDF" as="element()" />
    <xsl:variable name="root" select="/" as="node()" />
    
    <xsl:variable name="default-labels" select="document(concat($def-lang,'.xml'))" />
    <xsl:variable name="labels" select="document(concat($lang,'.xml'))" />
    <xsl:variable name="possible-ontology-urls" select="($ontology-url,concat($ontology-url,'/'),concat($ontology-url,'#'))" as="xs:string+" />
    <xsl:variable name="mime-types" select="('jpg','image/jpg','jpeg','image/jpg','png','image/png')" as="xs:string+" />
    
    <xsl:variable name="prefixes-uris" as="xs:string*">
        <xsl:variable name="declared-prefixes" select="in-scope-prefixes($rdf)" as="xs:string*" />
        <xsl:variable name="declared-uris" select="for $prefix in $declared-prefixes return xs:string(namespace-uri-for-prefix($prefix,$rdf))" as="xs:string*" />
        
        <xsl:variable name="existing-uri" select="for $current in distinct-values(//element()/(@*:about | @*:resource | @*:ID | @*:datatype)) return if (starts-with($current,'http')) then $current else ()" as="xs:string*" />
        
        <xsl:variable name="non-declared-uris" as="xs:string*">
            <xsl:variable name="temp-non-declared" as="xs:string*">
                <xsl:for-each select="$existing-uri">
                    <xsl:variable name="index" select="if (contains(.,'#')) then f:string-first-index-of(.,'#') else f:string-last-index-of(replace(.,'://','---'),'/')" as="xs:integer?" />
                    <xsl:if test="exists($index) and substring(.,$index + 1) != ''">
                        <xsl:variable name="ns" select="substring(.,1,$index)" as="xs:string?" />
                        <xsl:if test="empty($declared-uris[. = $ns])">
                            <xsl:sequence select="xs:string($ns)" />
                        </xsl:if>
                    </xsl:if>
                </xsl:for-each>
            </xsl:variable>
            <xsl:sequence select="distinct-values($temp-non-declared)" />
        </xsl:variable>
        
        <xsl:variable name="non-declared-prefixes" as="xs:string*">
            <xsl:for-each select="$non-declared-uris">
                <xsl:variable name="string" select="substring(.,1,string-length(.) - 1)" as="xs:string" />
                <xsl:variable name="index" select="f:string-last-index-of($string,'/')" as="xs:integer?" />
                <xsl:variable name="selected" select="if ($index) then substring($string,$index + 1) else $string" as="xs:string" />
                <xsl:sequence select="lower-case(replace($selected,'\.|_| |:','-'))" />
            </xsl:for-each>
        </xsl:variable>
        
        <xsl:variable name="all-prefixes" select="($declared-prefixes,$non-declared-prefixes)" as="xs:string*" />
        <xsl:variable name="all-uris" select="($declared-uris,$non-declared-uris)" as="xs:string*" />
        
        <xsl:for-each select="1 to count($all-prefixes)">
            <xsl:variable name="i" select="." as="xs:integer"/>
            <xsl:sequence select="($all-prefixes[$i],$all-uris[$i])" />
        </xsl:for-each>
    </xsl:variable>
    
    <xsl:template match="rdf:RDF">
        <html lang="en-GB" xmlns="http://www.w3.org/1999/xhtml">
            <xsl:choose>
                <xsl:when test="owl:Ontology">
                    <xsl:apply-templates select="owl:Ontology" />
                </xsl:when>
                <xsl:otherwise>
                    <xsl:call-template name="structure" />
                </xsl:otherwise>
            </xsl:choose>
        </html>
    </xsl:template>
    
    <xsl:template name="htmlhead">
        <!--<meta content="text/html; charset=utf-8" http-equiv="Content-Type" />-->

        <link rel='stylesheet' id='generate-style-grid-css'  href='http://mmoon.org/wp-content/themes/generatepress/css/unsemantic-grid.min.css?ver=1.3.21' type='text/css' media='all' />
        <link rel='stylesheet' id='generate-style-css'  href='http://mmoon.org/wp-content/themes/generatepress/style.css?ver=1.3.21' type='text/css' media='all' />
        <style id='generate-style-inline-css' type='text/css'>
            body {
                background-color: #d0e8dd;
                color: #007896;
            }
            a, a:visited {
                color: #007896;
                text-decoration: none;
            }
            a:visited {
                color: #19a8a3;
            }

            a:hover, a:focus, a:active {
                color: #e87612;
            }
            body .grid-container {
                max-width: 1140px;
            }
            body, button, input, select, textarea {
                font-family: Tahoma, Geneva, sans-serif; font-size: 16px;
            }
            .main-title {
                font-weight: 300;
                font-size: 78px; }
            .site-description {
                font-weight: 300;
                font-size: 20px;
            }
            .main-navigation a, .menu-toggle {
                font-weight: 300;
                font-size: 17px;
            }
            .main-navigation .main-nav ul ul li a {
                font-size: 14px;
            }
            .widget-title {
                font-weight: 300;
                font-size: 23px;
            }
            .sidebar .widget, .footer-widgets .widget {
                font-size: 19px;
            }
            h1 {
                font-weight: 300;
                font-size: 40px;
            }
            h2 {
                font-weight: 300;
                font-size: 30px;
            }
            h3 {
                font-size: 20px;
            }
            .site-info {
                font-size: px;
            }
            .site-header {
                color: #3a3a3a;
            }
            .site-header a,.site-header a:visited {
                color: #ffffff;
            }
            .site-header a:hover {
                color: #efefef;
            }
            .main-title a,.main-title a:hover,.main-title a:visited {
                color: #ffffff;
            }
            .site-description {
                color: #cccccc;
            }
            .main-navigation,  .main-navigation ul ul {
                background-color: #000000;
            }
            .navigation-search input[type="search"],.navigation-search input[type="search"]:active {
                color: #847f67;
                background-color: #847f67;
            }
            .navigation-search input[type="search"]:focus {
                color: #ffffff;
                background-color: #847f67;
            }
            .main-navigation ul ul {
                background-color: #847f67;
            }
            .main-navigation .main-nav ul li a,.menu-toggle {
                color: #ffffff;
            }
            button.menu-toggle:hover,button.menu-toggle:active,button.menu-toggle:focus,.main-navigation .mobile-bar-items a,.main-navigation .mobile-bar-items a:hover,.main-navigation .mobile-bar-items a:focus {
                color: #ffffff;
            }
            .main-navigation .main-nav ul ul li a {
                color: #ffffff;
            }
            .main-navigation .main-nav ul li > a:hover, .main-navigation .main-nav ul li.sfHover > a {
                color: #ffffff;
                background-color: #847f67;
            }.main-navigation .main-nav ul ul li > a:hover, .main-navigation .main-nav ul ul li.sfHover > a {
                color: #212121;
                background-color: #847f67;
            }
            .main-navigation .main-nav ul .current-menu-item > a, .main-navigation .main-nav ul .current-menu-parent > a, .main-navigation .main-nav ul .current-menu-ancestor > a {
                color: #ffffff;
                background-color: #847f67;
            }
            .main-navigation .main-nav ul .current-menu-item > a:hover, .main-navigation .main-nav ul .current-menu-parent > a:hover, .main-navigation .main-nav ul .current-menu-ancestor > a:hover, .main-navigation .main-nav ul .current-menu-item.sfHover > a, .main-navigation .main-nav ul .current-menu-parent.sfHover > a, .main-navigation .main-nav ul .current-menu-ancestor.sfHover > a {
                color: #ffffff;
                background-color: #847f67;
            }
            .main-navigation .main-nav ul ul .current-menu-item > a, .main-navigation .main-nav ul ul .current-menu-parent > a, .main-navigation .main-nav ul ul .current-menu-ancestor > a {
                color: #212121;
                background-color: #847f67;
            }
            .main-navigation .main-nav ul ul .current-menu-item > a:hover, .main-navigation .main-nav ul ul .current-menu-parent > a:hover, .main-navigation .main-nav ul ul .current-menu-ancestor > a:hover,.main-navigation .main-nav ul ul .current-menu-item.sfHover > a, .main-navigation .main-nav ul ul .current-menu-parent.sfHover > a, .main-navigation .main-nav ul ul .current-menu-ancestor.sfHover > a {
                color: #212121;
                background-color: #847f67;
            }
            .inside-article, .comments-area, .page-header,.one-container .container,.paging-navigation,.inside-page-header {
                background-color: #FFFFFF;
                color: #3a3a3a;
            }
            .entry-meta {
                color: #888888;
            }
            .entry-meta a, .entry-meta a:visited {
                color: #666666;
            }
            .entry-meta a:hover {
                color: #847f67;
            }
            .sidebar .widget {
                background-color: #FFFFFF;
                color: #3a3a3a;
            }
            .sidebar .widget .widget-title {
                color: #000000;
            }
            .footer-widgets {
                background-color: #222222;
                color: #ffffff;
            }
            .footer-widgets a, .footer-widgets a:visited {
                color: #847f67;
            }
            .footer-widgets a:hover {
                color: #ffffff;
            }
            .footer-widgets .widget-title {
                color: #ffffff;
            }
            .site-info {
                background-color: #000000;
                color: #ffffff;
            }
            .site-info a, .site-info a:visited {
                color: #847f67;
            }
            .site-info a:hover {
                color: #ffffff;
            }
            input[type="text"], input[type="email"], input[type="url"], input[type="password"], input[type="search"], textarea {
                background-color: #FAFAFA;
                border-color: #CCCCCC;
                color: #666666;
            }
            input[type="text"]:focus, input[type="email"]:focus, input[type="url"]:focus, input[type="password"]:focus, input[type="search"]:focus, textarea:focus {
                background-color: #FFFFFF;
                color: #666666;
                border-color: #BFBFBF;
            }
            button, html input[type="button"], input[type="reset"], input[type="submit"],.button,.button:visited {
                background-color: #666666;
                color: #FFFFFF;
            }
            button:hover, html input[type="button"]:hover, input[type="reset"]:hover, input[type="submit"]:hover,.button:hover,button:focus, html input[type="button"]:focus, input[type="reset"]:focus, input[type="submit"]:focus,.button:focus,button:active, html input[type="button"]:active, input[type="reset"]:active, input[type="submit"]:active,.button:active {
                background-color: #847f67;
                color: #FFFFFF;
            }
            .main-navigation .mobile-bar-items a,.main-navigation .mobile-bar-items a:hover,.main-navigation .mobile-bar-items a:focus {
                color: #ffffff;
            }
            .inside-header {
                padding: 60px 40px 60px 40px;
            }
            .separate-containers .inside-article, .separate-containers .comments-area, .separate-containers .page-header, .separate-containers .paging-navigation, .one-container .site-content {
                padding: 50px 50px 50px 50px;
            }
            .ignore-x-spacing {
                margin-right: -50px;
                margin-bottom: 50px;
                margin-left: -50px;
            }
            .ignore-xy-spacing {
                margin-top: -50px;
                margin-right: -50px;
                margin-bottom: 50px;
                margin-left: -50px;
            }
            .main-navigation .main-nav ul li a,.menu-toggle,.main-navigation .mobile-bar-items a {
                padding-left: 20px;
                padding-right: 20px;
                line-height: 70px;
            }
            .nav-float-right .main-navigation .main-nav ul li a {
                line-height: 70px;
            }
            .main-navigation .main-nav ul ul li a {
                padding: 10px 20px 10px 20px;
            }
            .main-navigation ul ul {
                top: 70px;
            }
            .navigation-search {
                height: 70px;
                line-height: 0px;
            }
            .navigation-search input {
                height: 70px;
                line-height: 0px;
            }
            .widget-area .widget {
                padding: 50px 50px 50px 50px;
            }
            .footer-widgets {
                padding: 50px 0px 50px 0px;
            }
            .site-info {
                padding: 20px 0px 20px 0px;
            }
            .right-sidebar.separate-containers .site-main {
                margin: 15px 15px 15px 0px;
                padding: 0px;
            }
            .left-sidebar.separate-containers .site-main {
                margin: 15px 0px 15px 15px;
                padding: 0px;
            }
            .both-sidebars.separate-containers .site-main {
                margin: 15px;
                padding: 0px;
            }
            .both-right.separate-containers .site-main {
                margin: 15px 15px 15px 0px;
                padding: 0px;
            }
            .separate-containers .site-main {
                margin-top: 15px;
                margin-bottom: 15px;
                padding: 0px;
            }
            .separate-containers .page-header-image, .separate-containers .page-header-content, .separate-containers .page-header-image-single, .separate-containers .page-header-content-single {
                margin-top: 15px;
            }
            .both-left.separate-containers .site-main {
                margin: 15px 0px 15px 15px;
                padding: 0px;
            }
            .separate-containers .inside-right-sidebar, .inside-left-sidebar {
                margin-top: 15px;
                margin-bottom: 15px;
                padding-top: 0px;
                padding-bottom: 0px;
            }
            .separate-containers .widget, .separate-containers .hentry, .separate-containers .page-header, .widget-area .main-navigation {
                margin-bottom: 15px;
            }
            .both-left.separate-containers .inside-left-sidebar {
                margin-right: 7.5px;
                padding-right: 0px;
            }
            .both-left.separate-containers .inside-right-sidebar {
                margin-left: 7.5px;
                padding-left: 0px;
            }
            .both-right.separate-containers .inside-left-sidebar {
                margin-right: 7.5px;
                padding-right: 0px;
            }
            .both-right.separate-containers .inside-right-sidebar {
                margin-left: 7.5px;
                padding-left: 0px;
            }
            .main-navigation .mobile-bar-items a {
                padding-left: 20px;
                padding-right: 20px;
                line-height: 70px;
            }
        </style>
        <link rel='stylesheet' id='generate-mobile-style-css'  href='http://mmoon.org/wp-content/themes/generatepress/css/mobile.css?ver=1.3.21' type='text/css' media='all' />
        <link rel='stylesheet' id='generate-child-css'  href='http://mmoon.org/wp-content/themes/freelancer/style.css?ver=1448225708' type='text/css' media='all' />
        <link rel='stylesheet' id='superfish-css'  href='http://mmoon.org/wp-content/themes/generatepress/css/superfish.css?ver=1.3.21' type='text/css' media='all' />
        <link rel='stylesheet' id='fontawesome-css'  href='http://mmoon.org/wp-content/themes/generatepress/css/font-awesome.min.css?ver=4.5.0' type='text/css' media='all' />
        <script type='text/javascript' src='http://mmoon.org/wp-includes/js/jquery/jquery.js?ver=1.11.3'></script>
        <script type='text/javascript' src='http://mmoon.org/wp-includes/js/jquery/jquery-migrate.js?ver=1.2.1'></script>
        <link rel="EditURI" type="application/rsd+xml" title="RSD" href="http://mmoon.org/xmlrpc.php?rsd" />
        <link rel="wlwmanifest" type="application/wlwmanifest+xml" href="http://mmoon.org/wp-includes/wlwmanifest.xml" />
        <meta name="generator" content="WordPress 4.3.13" />
        <link rel='canonical' href='http://mmoon.org/sparql/' />
        <link rel='shortlink' href='http://mmoon.org/?p=190' />
        <!-- This code is added by WP Analytify (2.1.8) https://analytify.io/downloads/analytify-wordpress-plugin/ !-->
        <script>
            (function(i,s,o,g,r,a,m){i['GoogleAnalyticsObject']=r;i[r]=i[r]||function(){
            (i[r].q=i[r].q||[]).push(arguments)},i[r].l=1*new Date();a=s.createElement(o),
            m=s.getElementsByTagName(o)[0];a.async=1;a.src=g;m.parentNode.insertBefore(a,m)
            })


            (window,document,'script','//www.google-analytics.com/analytics.js','ga');
            ga('create', '', 'auto');ga('send', 'pageview');					</script>

        <!-- This code is added by WP Analytify (2.1.8) !--><meta name="viewport" content="width=device-width, initial-scale=1" />	<!--[if lt IE 9]>
		<link rel="stylesheet" href="http://mmoon.org/wp-content/themes/generatepress/css/ie.min.css" />
		<script src="http://mmoon.org/wp-content/themes/generatepress/js/html5shiv.js"></script>
	    <![endif]-->
        <link rel="icon" href="http://mmoon.org/wp-content/uploads/2015/11/cropped-rect5910-32x32.png" sizes="32x32" />
        <link rel="icon" href="http://mmoon.org/wp-content/uploads/2015/11/cropped-rect5910-192x192.png" sizes="192x192" />
        <link rel="apple-touch-icon-precomposed" href="http://mmoon.org/wp-content/uploads/2015/11/cropped-rect5910-180x180.png" />
        <meta name="msapplication-TileImage" content="http://mmoon.org/wp-content/uploads/2015/11/cropped-rect5910-270x270.png" />


        <!--<link href="{$css-location}owl.css" rel="stylesheet" type="text/css" />-->
        <!--<link href="{$css-location}Primer.css" rel="stylesheet" type="text/css" />-->
        <!--<link href="{$css-location}rec.css" rel="stylesheet" type="text/css" />-->
        <link href="mmoon.org/lode/extra.css" rel="stylesheet" type="text/css" />
        <link rel="shortcut icon" href="mmoon.org/lode/favicon.ico" />
        <script src="mmoon.org/lode/jquery.js"><!-- Comment for compatibility --></script>
        <script src="mmoon.org/lode/jquery.scrollTo.js"><!-- Comment for compatibility --></script>
        <script src="mmoon.org/lode/marked.min.js"><!-- Comment for compatibility --></script>
        <script>
            $(document).ready(
            function () {
            jQuery(".markdown").each(function(el){
            jQuery(this).after(marked(jQuery(this).text())).remove()});
            var list = $('a[name="<xsl:value-of select="$ontology-url" />"]');
            if (list.size() != 0) {
            var element = list.first();
            $.scrollTo(element);
            }
            });
        </script>


    </xsl:template>
    
    <xsl:template name="structure">
        <xsl:variable name="titles" select="dc:title|dcterms:title" as="element()*" />
        <head>
            <xsl:choose>
                <xsl:when test="$titles">
                    <xsl:apply-templates select="$titles" mode="head" />
                </xsl:when>
                <xsl:otherwise>
                    <xsl:apply-templates select="rdfs:label" mode="head" />
                </xsl:otherwise>
            </xsl:choose>
            <!--<xsl:apply-templates mode="head" />-->
            <xsl:call-template name="htmlhead" />
        </head>

        <body itemtype='http://schema.org/WebPage' itemscope='itemscope' class="page page-id-190 page-template no-sidebar nav-below-header contained-header one-container active-footer-widgets-3 nav-search-enabled nav-aligned-center header-aligned-center">
            <a class="screen-reader-text skip-link" href="#content" title="Skip to content">Skip to content</a>
            <header itemtype="http://schema.org/WPHeader" itemscope="itemscope" id="masthead" class="site-header grid-container grid-parent">
                <div class="inside-header"><div class="site-logo">
                    <a href="http://mmoon.org/" title="MMoOn" rel="home"><img class="header-image" src="http://mmoon.org/wp-content/uploads/2015/11/Logo.png" alt="MMoOn" title="MMoOn" /></a>
                </div></div><!-- .inside-header -->
            </header><!-- #masthead -->
            <nav itemtype="http://schema.org/SiteNavigationElement" itemscope="itemscope" id="site-navigation" class="main-navigation grid-container grid-parent">
                <div class="inside-navigation grid-container grid-parent">
                    <form method="get" class="search-form navigation-search" action="http://mmoon.org/"><input type="search" class="search-field" value="" name="s" title="Search" /></form>
                    <div class="mobile-bar-items"><span class="search-item" title="Search"><a href="#"><i class="fa fa-fw fa-search"></i></a></span></div><!-- .mobile-bar-items -->
                    <button class="menu-toggle" aria-controls="primary-menu" aria-expanded="false"><span class="mobile-menu">Menu</span></button>
                    <div id="primary-menu" class="main-nav">
                        <ul id="menu-menu-1" class=" menu sf-menu">
                            <li id="menu-item-183" class="menu-item menu-item-type-post_type menu-item-object-page menu-item-183"><a href="http://mmoon.org/feedback/">Feedback</a></li>
                            <li id="menu-item-185" class="menu-item menu-item-type-post_type menu-item-object-page menu-item-185"><a href="http://mmoon.org/mmoon-core-model/">MMoOn Core Model</a></li>
                            <li id="menu-item-186" class="menu-item menu-item-type-post_type menu-item-object-page menu-item-186"><a href="http://mmoon.org/publications/">Publications</a></li>
                            <li class="search-item" title="Search"><a href="#"><i class="fa fa-fw fa-search"></i></a></li>
                        </ul>
                    </div>
                </div><!-- .inside-navigation -->
            </nav><!-- #site-navigation -->
            <div id="page" class="hfeed site grid-container container grid-parent">
            <div id="content" class="site-content">
            <div id="primary" class="content-area grid-parent grid-100 tablet-grid-100">
            <main id="main" class="site-main">
            <article id="post-190" class="post-190 page type-page status-publish hentry" itemtype='http://schema.org/CreativeWork' itemscope='itemscope'>
            <div class="inside-article">
                <header class="entry-header"><h1 class="entry-title" itemprop="headline">



                <xsl:choose>
                    <xsl:when test="$titles">
                        <xsl:apply-templates select="$titles" mode="ontology" />
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:apply-templates select="rdfs:label" mode="ontology" />
                    </xsl:otherwise>
                </xsl:choose></h1>
                <xsl:call-template name="get.ontology.url" />
                <xsl:call-template name="get.version" />
                <xsl:call-template name="get.author" />
                <xsl:call-template name="get.publisher" />
                <xsl:call-template name="get.imports" />
                <xsl:apply-templates select="dc:rights|dcterms:rights" />


                </header><!-- .entry-header -->
            <!--<div class="entry-content" itemprop="text">-->


            <xsl:apply-templates select="rdfs:comment" mode="ontology" />
            <xsl:call-template name="get.toc" />
            <xsl:apply-templates select="dc:description[normalize-space() != ''] , dc:description[@*:resource]" mode="ontology" />
            <xsl:call-template name="get.classes" />
            <xsl:call-template name="get.objectproperties" />
            <xsl:call-template name="get.dataproperties" />
            <xsl:call-template name="get.namedindividuals" />
            <xsl:call-template name="get.annotationproperties" />
            <xsl:call-template name="get.generalaxioms" />
            <xsl:call-template name="get.swrlrules" />            
            <xsl:call-template name="get.namespacedeclarations" />

            <p class="endnote">This HTML document was obtained by processing the OWL ontology source code through <a href="http://www.essepuntato.it/lode">LODE</a>, <em>Live OWL Documentation Environment</em>, developed by <a href="http://www.essepuntato.it">Silvio Peroni</a>.</p>


            <!--</div>&lt;!&ndash; .entry-content &ndash;&gt;-->
            </div><!-- .inside-article -->
            </article><!-- #post-## -->
            </main><!-- #main -->
            </div><!-- #primary -->
            </div><!-- #content -->
            </div><!-- #page -->
            <div class="site-footer">
                <div id="footer-widgets" class="site footer-widgets">
                    <div class="inside-footer-widgets grid-container grid-parent">
                        <div class="footer-widget-1 grid-parent grid-33 tablet-grid-50">
                            <aside id="text-2" class="widget inner-padding widget_text">
                                <h4 class="widget-title">Contact:</h4>
                                <div class="textwidget">
                                    <p>Bettina Klimek<br />University of Leipzig<br />e-mail:<br />klimek@informatik.uni-leipzig.de<br />http://aksw.org/BettinaKlimek.html</p>
                                </div>
                            </aside>
                        </div>
                        <div class="footer-widget-2 grid-parent grid-33 tablet-grid-50">
                            <aside id="text-4" class="widget inner-padding widget_text">
                                <div class="textwidget">
                                    <a href="http://www.uni-leipzig.de/">
                                        <img src="http://sabre2014.infai.org/lib/tpl/sabreconference/sabre2012/logo-unileipzig.png"  class="alignright" style="width:220px;" />
                                    </a>
                                </div>
                            </aside>
                            <aside id="text-6" class="widget inner-padding widget_text">
                                <div class="textwidget">
                                    <a href="http://infai.org/en/Welcome">
                                        <img src="http://aksw.org/extensions/site/sites//local/images/logo-infai.png"  class="alignright" style="width:220px;  margin: 10px auto 10px auto" />
                                    </a>
                                </div>
                            </aside>
                            <aside id="text-7" class="widget inner-padding widget_text">
                                <div class="textwidget">
                                    <a href="http://www.lider-project.eu/">
                                        <img src="http://lider-project.eu/sites/default/files/logo.jpg"  class="alignright" style="width:220px;" />
                                    </a>
                                </div>
                            </aside>
                        </div>
                        <div class="footer-widget-3 grid-parent grid-33 tablet-grid-50">
                            <aside id="text-5" class="widget inner-padding widget_text">
                                <div class="textwidget">
                                <a href="http://mmoon.org/wp-content/uploads/2017/08/aksw_logo.png">
                                    <img src="http://aksw.org/extensions/site/sites//local/images/logo-aksw.png"  class="alignright" style="width:150px;  margin: 5px auto 5px auto" />
                                </a>
                                </div>
                            </aside>
                            <aside id="text-3" class="widget inner-padding widget_text">
                                <div class="textwidget">
                                <a href="http://creativecommons.org/licenses/by/4.0/">
                                    <img src="http://lemon-model.net/img/cc-by.png"  class="alignright" style="width:150px;" />
                                </a>
                            </div>
                            </aside>
                        </div>
                    </div>
                </div>
            </div><!-- .site-footer -->

            <script type='text/javascript' src='http://mmoon.org/wp-content/themes/generatepress/js/navigation.js?ver=1.3.21'></script>
            <script type='text/javascript' src='http://mmoon.org/wp-content/themes/generatepress/js/superfish.min.js?ver=1.3.21'></script>
            <script type='text/javascript' src='http://mmoon.org/wp-includes/js/hoverIntent.js?ver=1.8.1'></script>
            <script type='text/javascript' src='http://mmoon.org/wp-content/themes/generatepress/js/navigation-search.js?ver=1.3.21'></script>

        </body>



     </xsl:template>
    
    <xsl:template match="owl:Ontology">
        <xsl:call-template name="structure" />
    </xsl:template>
    
    <xsl:template match="dc:description[f:isInLanguage(.)][normalize-space() != '']" mode="ontology">
        <h2 id="introduction"><xsl:value-of select="f:getDescriptionLabel('introduction')" /></h2>
        <xsl:call-template name="get.content" />
    </xsl:template>
    
    <xsl:template match="dc:description[@*:resource]" mode="ontology">
        <xsl:variable name="url" select="@*:resource" />
        <xsl:variable name="index" select="f:string-last-index-of($url,'\.')" as="xs:integer?" />
        <xsl:variable name="extension" select="substring($url,$index + 1)" as="xs:string?" />
        
        <p class="image">
            <!-- <span><xsl:value-of select="$index,$extension,string-length($url)" separator=" - " /></span>  -->
            <object data="{@*:resource}">
                <xsl:if test="$extension != ''">
                    <xsl:variable name="mime" select="$mime-types[index-of($mime-types,$extension) + 1]" as="xs:string?" />
                    <xsl:if test="$mime != ''">
                        <xsl:attribute name="type" select="$mime" />
                    </xsl:if>
                </xsl:if>
            </object>
        </p>
    </xsl:template>
    
    <xsl:template match="dc:description[f:isInLanguage(.)][normalize-space() != '']">
        <div class="info">
            <xsl:call-template name="get.content" />
        </div>
    </xsl:template>
    
    <xsl:template match="dc:description[@*:resource]">
        <xsl:variable name="url" select="@*:resource" />
        <xsl:variable name="index" select="f:string-last-index-of($url,'.')" as="xs:integer?" />
        <xsl:variable name="extension" select="substring($url,$index + 1)" as="xs:string?" />
        
        <p class="image">
            <object data="{@*:resource}">
                <xsl:if test="$extension != ''">
                    <xsl:variable name="mime" select="$mime-types[index-of($mime-types,$extension) + 1]" as="xs:string?" />
                    <xsl:if test="$mime != ''">
                        <xsl:attribute name="type" select="$mime" />
                    </xsl:if>
                </xsl:if>
            </object>
        </p>
    </xsl:template>
    
    <xsl:template match="rdfs:comment[f:isInLanguage(.)]" mode="ontology">
        <h2><xsl:value-of select="f:getDescriptionLabel('abstract')" /></h2>
        <xsl:call-template name="get.content" />
    </xsl:template>
    
    <xsl:template match="rdfs:comment[f:isInLanguage(.)]">
        <div class="comment">
            <xsl:call-template name="get.content" />
        </div>
    </xsl:template>
    
    <xsl:template match="dc:rights[f:isInLanguage(.)]|dcterms:rights[ancestor::owl:Ontology][f:isInLanguage(.)]">
        <div class="copyright">
            <xsl:call-template name="get.content" />
        </div>
    </xsl:template>
    
    <xsl:template match="dc:title[f:isInLanguage(.)] | dcterms:title[f:isInLanguage(.)]" mode="ontology">
        <h1>
            <xsl:call-template name="get.title" />
        </h1>
    </xsl:template>
    
    <xsl:template match="rdfs:label[f:isInLanguage(.)]" mode="ontology">
        <h1>
            <xsl:call-template name="get.title" />
        </h1>
    </xsl:template>
    
    <xsl:template match="owl:imports">
        <dd>
            <a href="{@*:resource}">
                <xsl:value-of select="@*:resource" />
            </a>
        </dd>
    </xsl:template>
    
    <xsl:template match="dc:title[f:isInLanguage(.)]">
        <xsl:call-template name="get.title" />
    </xsl:template>
    
    <xsl:template match="dc:date|dcterms:date[ancestor::owl:Ontology]">
        <dt><xsl:value-of select="f:getDescriptionLabel('date')" />:</dt>
        <dd>
            <xsl:choose>
                <xsl:when test="matches(.,'\d\d\d\d-\d\d-\d\d')">
                    <xsl:variable name="tokens" select="tokenize(.,'-')" />
                    <xsl:value-of select="$tokens[3],$tokens[2],$tokens[1]" separator="/" />
                </xsl:when>
                <xsl:otherwise>
                    <xsl:apply-templates />
                </xsl:otherwise>
            </xsl:choose>
        </dd>
    </xsl:template>
    
    <xsl:template match="owl:versionInfo[f:isInLanguage(.)]">
        <dt><xsl:value-of select="f:getDescriptionLabel('currentversion')" />:</dt>
        <dd><xsl:apply-templates /></dd>
    </xsl:template>
    
    <xsl:template match="owl:priorVersion | owl:backwardCompatibleWith | owl:incompatibleWith">
        <xsl:variable name="versionLabel" select="if (self::owl:priorVersion) then 'previousversion' else if (self::owl:backwardCompatibleWith) then 'backwardcompatiblewith' else 'incompatibleWith'" />
        <dt><xsl:value-of select="f:getDescriptionLabel($versionLabel)" />:</dt>
        <dd>
            <xsl:choose>
                <xsl:when test="exists(@*:resource)">
                    <a href="{@*:resource}">
                        <xsl:value-of select="@*:resource" />
                    </a>
                    <xsl:text> (</xsl:text>
                    <a href="http://www.essepuntato.it/lode/owlapi/{@*:resource}"><xsl:value-of select="f:getDescriptionLabel('visualiseitwith')" /> LODE</a>
                    <xsl:text>)</xsl:text>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:apply-templates />
                </xsl:otherwise>
            </xsl:choose>
        </dd>
    </xsl:template>
    
    <xsl:template match="dc:creator|dc:contributor|dcterms:creator[ancestor::owl:Ontology]|dcterms:contributor[ancestor::owl:Ontology]|dc:publisher[ancestor::owl:Ontology]|dcterms:publisher[ancestor::owl:Ontology]">
        <xsl:choose>
            <xsl:when test="@*:resource">
                <dd>
                    <a href="{@*:resource}">
                        <xsl:value-of select="@*:resource" />
                    </a>
                </dd>
            </xsl:when>
            <xsl:otherwise>
                <dd>
                    <xsl:apply-templates />
                </dd>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <xsl:template match="dc:title[f:isInLanguage(.)]|dcterms:title[f:isInLanguage(.)]" mode="head">
        <title><xsl:value-of select="tokenize(.//text(),$n)[1]" /></title>
    </xsl:template>
    
    <xsl:template match="rdfs:label[f:isInLanguage(.)]" mode="head">
        <title><xsl:value-of select="tokenize(.//text(),$n)[1]" /></title>
    </xsl:template>
    
    <xsl:template match="element()|text()" mode="head" />
    <xsl:template match="element()" mode="ontology" />
    <xsl:template match="element()|text()[normalize-space() = '']" />
    
    <xsl:template match="owl:Class">
        <xsl:variable name="anchor" select="f:getAnchor(@*:about|@*:ID)" as="xs:string" />
        <div id="{$anchor}" class="entity">
            <xsl:call-template name="get.entity.name">
                <xsl:with-param name="toc" select="'classes'" tunnel="yes" as="xs:string" />
                <xsl:with-param name="toc.string" select="f:getDescriptionLabel('classtoc')" tunnel="yes" as="xs:string" />
            </xsl:call-template>
            <xsl:call-template name="get.entity.metadata" />
            <xsl:apply-templates select="rdfs:comment" />
            <xsl:call-template name="get.class.description" />
            <xsl:apply-templates select="dc:description[normalize-space() != ''] , dc:description[@*:resource]" />
        </div>
    </xsl:template>
    
    <xsl:template match="owl:NamedIndividual">
        <xsl:variable name="anchor" select="f:getAnchor(@*:about|@*:ID)" as="xs:string" />
        <div id="{$anchor}" class="entity">
            <xsl:call-template name="get.entity.name" />
            <xsl:call-template name="get.entity.metadata" />
            <xsl:apply-templates select="rdfs:comment" />
            <xsl:call-template name="get.individual.description" />
            <xsl:apply-templates select="dc:description[normalize-space() != ''] , dc:description[@*:resource]" />
        </div>
    </xsl:template>
    
    <xsl:template match="owl:ObjectProperty | owl:DatatypeProperty | owl:AnnotationProperty">
        <xsl:variable name="anchor" select="f:getAnchor(@*:about|@*:ID)" as="xs:string" />
        <div id="{$anchor}" class="entity">
            <xsl:call-template name="get.entity.name">
                <xsl:with-param name="toc" select="if (self::owl:ObjectProperty) then 'objectproperties' else if (self::owl:AnnotationProperty) then 'annotationproperties' else 'dataproperties'" tunnel="yes" as="xs:string" />
                <xsl:with-param name="toc.string" select="if (self::owl:ObjectProperty) then f:getDescriptionLabel('objectpropertytoc') else if (self::owl:AnnotationProperty) then f:getDescriptionLabel('annotationpropertytoc') else f:getDescriptionLabel('datapropertytoc')" tunnel="yes" as="xs:string" />
            </xsl:call-template>
            <xsl:call-template name="get.entity.metadata" />
            <xsl:apply-templates select="rdfs:comment" />
            <xsl:call-template name="get.property.description" />
            <xsl:apply-templates select="dc:description[normalize-space() != ''] , dc:description[@*:resource]" />
        </div>
    </xsl:template>
    
    <xsl:template match="rdfs:range | rdfs:domain">
        <dd>
            <xsl:apply-templates select="@*:resource | element()">
                <xsl:with-param name="type" select="'class'" as="xs:string" tunnel="yes" />
            </xsl:apply-templates>
        </dd>
    </xsl:template>
    
    <xsl:template match="owl:propertyChainAxiom">
        <dd>
            <xsl:for-each select="element()">
                <xsl:apply-templates select="." />
                <xsl:if test="position() != last()">
                    <xsl:text> </xsl:text>
                    <span class="logic">o</span>
                    <xsl:text> </xsl:text>
                </xsl:if>
            </xsl:for-each>
        </dd>
    </xsl:template>
    
    <xsl:template match="owl:inverseOf">
        <span class="logic">inverse</span>
        <xsl:text> </xsl:text>
        <xsl:apply-templates select="@*:resource" />
    </xsl:template>
    
    <xsl:template match="rdfs:label[f:isInLanguage(.)]">
        <h3>
            <xsl:apply-templates />
            <xsl:call-template name="get.entity.type.descriptor">
                <xsl:with-param name="iri" select="ancestor::element()/(@*:about|@*:ID)" />
            </xsl:call-template>
            <xsl:if test="exists(dc:title[f:isInLanguage(.)])">
                <br />
                <xsl:apply-templates select="dc:title" />
            </xsl:if>
        </h3>
    </xsl:template>
    
    <xsl:template match="element()" mode="toc">
        <li>
            <a href="#{f:getAnchor(@*:about|@*:ID)}" title="{@*:about|@*:ID}">
                <xsl:choose>
                    <xsl:when test="exists(rdfs:label)">
                        <xsl:value-of select="rdfs:label[f:isInLanguage(.)]" />
                    </xsl:when>
                    <xsl:otherwise>
                        <span>
                            <xsl:value-of select="f:getLabel(@*:about|@*:ID)" />
                        </span>
                    </xsl:otherwise>
                </xsl:choose>
            </a>
        </li>
    </xsl:template>
    
    <xsl:template match="owl:equivalentClass | rdfs:subClassOf | rdfs:subPropertyOf">
    	<xsl:param name="list" select="true()" tunnel="yes" as="xs:boolean" />
    	<xsl:choose>
    		<xsl:when test="$list">
    			<dd>
            		<xsl:apply-templates select="attribute() | element()" />
        		</dd>
    		</xsl:when>
    		<xsl:otherwise>
    			<xsl:apply-templates select="attribute() | element()" />
    		</xsl:otherwise>
    	</xsl:choose>
    </xsl:template>
    
    <xsl:template match="owl:hasKey">
        <dd>
            <xsl:for-each select="element()">
                <xsl:if test="exists(preceding-sibling::element())">
                    <xsl:text> , </xsl:text>
                </xsl:if>
                <xsl:apply-templates select=".">
                    <xsl:with-param name="type" select="'property'" as="xs:string" tunnel="yes" />
                </xsl:apply-templates>
            </xsl:for-each>
        </dd>
    </xsl:template>
    
    <xsl:template match="rdf:type">
        <dd>
            <xsl:apply-templates select="@*:resource" />
        </dd>
    </xsl:template>
    
    <xsl:template match="@*:about | @*:resource | @*:ID | @*:datatype">
        <xsl:param name="type" select="''" as="xs:string" tunnel="yes" />
        
        <!--<xsl:variable name="anchor" select="f:findEntityId(.,$type)" as="xs:string" />-->
        <xsl:variable name="label" select="f:getLabel(.)" as="xs:string" />
        <!--<xsl:variable name="url" select="@*:about|@*:ID" as="xs:string" />-->
        <!--<xsl:value-of select="@*:about|@*:ID" />-->

        <a href="{.}" title="{.}">
            <xsl:value-of select="$label" />
        </a>

        <!--<xsl:choose>-->
            <!--<xsl:when test="$anchor = ''">-->
                <!--&lt;!&ndash;<span class="dotted" title="{.}">&ndash;&gt;-->
                    <!--&lt;!&ndash;<xsl:value-of select="$label" />&ndash;&gt;-->
                <!--&lt;!&ndash;</span>&ndash;&gt;-->
                <!--&lt;!&ndash;<a href="{@*:about|@*:ID}" title="{.}">&ndash;&gt;-->
                    <!--&lt;!&ndash;<xsl:value-of select="@*:about|@*:ID" />&ndash;&gt;-->
                <!--&lt;!&ndash;</a>&ndash;&gt;-->
                <!--<a href="{.}" title="{.}">-->
                    <!--<xsl:value-of select="$label" />-->
                <!--</a>-->
            <!--</xsl:when>-->
            <!--<xsl:otherwise>-->
                <!--<a href="#{$anchor}" title="{.}">-->
                    <!--<xsl:value-of select="$label" />-->
                <!--</a>-->
            <!--</xsl:otherwise>-->
        <!--</xsl:choose>-->

        <xsl:call-template name="get.entity.type.descriptor">
            <xsl:with-param name="iri" select="." as="xs:string" />
        </xsl:call-template>
    </xsl:template>
    
    <xsl:function name="f:findEntityId" as="xs:string">
        <xsl:param name="iri" as="xs:string" />
        <xsl:param name="type" as="xs:string" />
        
        <xsl:variable name="el" select="$root//rdf:RDF/element()[(@*:about = $iri or @*:ID = $iri) and exists(element())]" as="element()*" />
        <xsl:choose>
            <xsl:when test="exists($el)">
                <xsl:choose>
                    <xsl:when test="$type = 'class'">
                        <xsl:value-of select="generate-id($el[local-name() = 'Class'][1])" />
                    </xsl:when>
                    <xsl:when test="$type = 'property'">
                        <xsl:value-of select="generate-id($el[local-name() = 'ObjectProperty' or local-name() = 'DatatypeProperty'][1])" />
                    </xsl:when>
                    <xsl:when test="$type = 'annotation'">
                        <xsl:value-of select="generate-id($el[local-name() = 'AnnotationProperty'][1])" />
                    </xsl:when>
                    <xsl:when test="$type = 'individual'">
                        <xsl:value-of select="generate-id($el[local-name() = 'NamedIndividual'][1])" />
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:value-of select="generate-id($el[1])" />
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="''" />
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>
    
    <!-- <xsl:function name="f:getLabel" as="xs:string">
        <xsl:param name="iri" as="xs:string" />
        
        <xsl:variable name="node" select="$root//rdf:RDF/element()[(@*:about = $iri or @*:ID = $iri) and exists(rdfs:label)][1]" as="element()*" />
        <xsl:choose>
            <xsl:when test="exists($node/rdfs:label)">
                <xsl:value-of select="$node/rdfs:label[f:isInLanguage(.)]" />
            </xsl:when>
            <xsl:otherwise>
                <xsl:variable name="prefix" select="f:getPrefixFromIRI($iri)" as="xs:string*" />
                <xsl:choose>
                    <xsl:when test="empty($prefix)">
                        <xsl:value-of select="$iri" />
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:value-of select="concat($prefix,':',substring-after($iri, $prefixes-uris[index-of($prefixes-uris,$prefix)[1] + 1]))" />
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function> -->
    <xsl:function name="f:getLabel" as="xs:string">
        <xsl:param name="iri" as="xs:string" />
        
        <xsl:variable name="node" select="$root//rdf:RDF/element()[(@*:about = $iri or @*:ID = $iri) and exists(rdfs:label)][1]" as="element()*" />
        <xsl:choose>
            <xsl:when test="exists($node/rdfs:label)">
                <xsl:value-of select="$node/rdfs:label[f:isInLanguage(.)]" />
            </xsl:when>
            <xsl:otherwise>
                <xsl:variable name="localName" as="xs:string?">
                    <xsl:variable 
                        name="current-index" 
                        select="if (contains($iri,'#')) 
                                    then f:string-first-index-of($iri,'#') 
                                    else f:string-last-index-of(replace($iri,'://','---'),'/')" 
                        as="xs:integer?" />
                    <xsl:if test="exists($current-index) and string-length($iri) != $current-index">
                        <xsl:sequence select="substring($iri,$current-index + 1)" />
                    </xsl:if>
                </xsl:variable>
                
                <xsl:choose>
                    <xsl:when test="string-length($localName) = 0">
                        <xsl:variable name="prefix" select="f:getPrefixFromIRI($iri)" as="xs:string*" />
                        <xsl:choose>
                            <xsl:when test="empty($prefix)">
                                <xsl:value-of select="$iri" />
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:value-of select="concat($prefix,':',substring-after($iri, $prefixes-uris[index-of($prefixes-uris,$prefix)[1] + 1]))" />
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:variable name="camelCase" select="replace($localName,'([A-Z])',' $1')" />
                        <xsl:variable name="underscoreOrDash" select="replace($camelCase,'(_|-)',' ')" />
                        <xsl:value-of select="normalize-space($underscoreOrDash)" />
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>

    <xsl:function name="f:getAnchor" as="xs:string">
        <xsl:param name="iri" as="xs:string" />
        <xsl:variable name="localName" as="xs:string?">
            <xsl:variable
                name="current-index"
                select="if (contains($iri,'#'))
                    then f:string-first-index-of($iri,'#')
                    else f:string-last-index-of(replace($iri,'://','---'),'/')"
                as="xs:integer?" />
            <xsl:if test="exists($current-index) and string-length($iri) != $current-index">
                <xsl:sequence select="substring($iri,$current-index + 1)" />
            </xsl:if>
        </xsl:variable>
        <xsl:choose>
            <xsl:when test="string-length($localName) = 0">
                <xsl:variable name="prefix" select="f:getPrefixFromIRI($iri)" as="xs:string*" />
                <xsl:choose>
                    <xsl:when test="empty($prefix)">
                        <xsl:value-of select="$iri" />
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:value-of select="concat($prefix,':',substring-after($iri, $prefixes-uris[index-of($prefixes-uris,$prefix)[1] + 1]))" />
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:when>
            <xsl:otherwise>
                 <xsl:value-of select="$localName" />
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>
    
    <xsl:template match="owl:Class[not(parent::rdf:RDF)] | rdfs:Datatype[not(parent::rdf:RDF)] | owl:DataRange[not(parent::rdf:RDF)]">
        <xsl:apply-templates />
    </xsl:template>
    
    <xsl:template match="owl:Restriction">
        <xsl:call-template name="exec.owlRestriction" />
    </xsl:template>
    
    <xsl:template match="owl:oneOf">
        <xsl:text>{ </xsl:text>
        <xsl:for-each select="element()">
            <xsl:apply-templates select=".">
                <xsl:with-param name="type" select="'namedindividual'" tunnel="yes" />
            </xsl:apply-templates>
            <xsl:if test="position() != last()">
                <xsl:text> , </xsl:text>
            </xsl:if>
        </xsl:for-each>
        <xsl:text> }</xsl:text>
    </xsl:template>
    
    <xsl:template match="rdf:Description[rdf:type/@*:resource = 'http://www.w3.org/1999/02/22-rdf-syntax-ns#List'] | rdf:List">
        <xsl:apply-templates select="rdf:first , rdf:rest" />
    </xsl:template>
    
    <xsl:template match="rdf:first">
        <xsl:choose>
            <xsl:when test="normalize-space()">
                <xsl:text>"</xsl:text>
                <xsl:value-of select="normalize-space()" />
                <xsl:text>"</xsl:text>
            </xsl:when>
            <xsl:otherwise>
                <xsl:apply-templates select="@*:resource" />
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <xsl:template match="rdf:rest">
        <xsl:if test="rdf:Description[rdf:type/@*:resource = 'http://www.w3.org/1999/02/22-rdf-syntax-ns#List'] | rdf:List">
            <xsl:text> , </xsl:text>
        </xsl:if>
        <xsl:apply-templates select="rdf:Description[rdf:type/@*:resource = 'http://www.w3.org/1999/02/22-rdf-syntax-ns#List'] | rdf:List" />
    </xsl:template>
    
    <xsl:template match="/rdf:RDF/rdf:Description[exists(rdf:type[@*:resource = 'http://www.w3.org/2002/07/owl#AllDisjointClasses'])]">
        <div id="{generate-id()}" class="entity">
            <h3><xsl:value-of select="f:getDescriptionLabel('disjointclasses')" /><xsl:text> </xsl:text></h3>
            <p>
                <xsl:for-each select="owl:members/rdf:Description/(@*:about|@*:ID)">
                    <xsl:apply-templates select=".">
                        <xsl:with-param name="type" select="'class'" as="xs:string" tunnel="yes" />
                    </xsl:apply-templates>
                    <xsl:if test="position() != last()">
                        <xsl:text>, </xsl:text>
                    </xsl:if>
                </xsl:for-each>
            </p>
        </div>
    </xsl:template>
    
    <xsl:template match="/rdf:RDF/owl:Restriction[exists(rdfs:subClassOf)]">
        <div id="{generate-id()}" class="entity">
            <h3><xsl:value-of select="f:getDescriptionLabel('subclassdefinition')" /><xsl:text> </xsl:text></h3>
            <p>
                <xsl:call-template name="exec.owlRestriction" />
                <strong><xsl:text> </xsl:text><xsl:value-of select="f:getDescriptionLabel('issubclassof')" /></strong>
            </p>
            <p style="text-align:right">
                <xsl:apply-templates select="rdfs:subClassOf">
                    <xsl:with-param name="list" select="false()" tunnel="yes" />
                </xsl:apply-templates>
            </p>
        </div>
    </xsl:template>
    
    <xsl:template match="/rdf:RDF/owl:Restriction[exists(owl:equivalentClass)]">
        <div id="{generate-id()}" class="entity">
            <h3><xsl:value-of select="f:getDescriptionLabel('equivalentdefinition')" /><xsl:text> </xsl:text></h3>
            <p>
                <xsl:call-template name="exec.owlRestriction" />
                <strong><xsl:text> </xsl:text><xsl:value-of select="f:getDescriptionLabel('isequivalentto')" /></strong>
            </p>
            <p style="text-align:right">
                <xsl:apply-templates select="owl:equivalentClass">
                    <xsl:with-param name="list" select="false()" tunnel="yes" />
                </xsl:apply-templates>
            </p>
        </div>
    </xsl:template>
    
    <xsl:template name="exec.owlRestriction">
        <xsl:apply-templates select="owl:onProperty" />
        <xsl:apply-templates select="element()[not(self::owl:onProperty|self::owl:onClass|self::rdfs:subClassOf|self::owl:equivalentClass)]" />
        <xsl:apply-templates select="owl:onClass" />
    </xsl:template>
    
    <xsl:template match="/rdf:RDF/owl:Class[empty(@*:about | @*:ID) and exists(rdfs:subClassOf)]">
        <div id="{generate-id()}" class="entity">
            <h3><xsl:value-of select="f:getDescriptionLabel('subclassdefinition')" /><xsl:text> </xsl:text></h3>
            <p>
            	<xsl:apply-templates select="element()[not(self::rdfs:subClassOf)]" />
                <strong><xsl:text> </xsl:text><xsl:value-of select="f:getDescriptionLabel('issubclassof')" /></strong>
           	</p>
           	<p style="text-align:right">
            	<xsl:apply-templates select="rdfs:subClassOf">
            		<xsl:with-param name="list" select="false()" tunnel="yes" />
            	</xsl:apply-templates>
            </p>
        </div>
    </xsl:template>
    
    <xsl:template match="/rdf:RDF/owl:Class[empty(@*:about | @*:ID) and exists(owl:equivalentClass)]">
        <div id="{generate-id()}" class="entity">
            <h3><xsl:value-of select="f:getDescriptionLabel('equivalentdefinition')" /><xsl:text> </xsl:text></h3>
            <p>
            	<xsl:apply-templates select="element()[not(self::owl:equivalentClass)]" />
                <strong><xsl:text> </xsl:text><xsl:value-of select="f:getDescriptionLabel('isequivalentto')" /></strong>
           	</p>
           	<p style="text-align:right">
            	<xsl:apply-templates select="owl:equivalentClass">
            		<xsl:with-param name="list" select="false()" tunnel="yes" />
            	</xsl:apply-templates>
            </p>
        </div>
    </xsl:template>
    
    <xsl:template match="rdf:type[@*:resource = 'http://www.w3.org/2002/07/owl#FunctionalProperty']">
        <xsl:value-of select="f:getDescriptionLabel('functional')" />
    </xsl:template>
    
    <xsl:template match="rdf:type[@*:resource = 'http://www.w3.org/2002/07/owl#InverseFunctionalProperty']">
        <xsl:value-of select="f:getDescriptionLabel('inversefunctional')" />
    </xsl:template>
    
    <xsl:template match="rdf:type[@*:resource = 'http://www.w3.org/2002/07/owl#ReflexiveProperty']">
        <xsl:value-of select="f:getDescriptionLabel('reflexive')" />
    </xsl:template>
    
    <xsl:template match="rdf:type[@*:resource = 'http://www.w3.org/2002/07/owl#IrreflexiveProperty']">
        <xsl:value-of select="f:getDescriptionLabel('irreflexive')" />
    </xsl:template>
    
    <xsl:template match="rdf:type[@*:resource = 'http://www.w3.org/2002/07/owl#SymmetricProperty']">
        <xsl:value-of select="f:getDescriptionLabel('symmetric')" />
    </xsl:template>
    
    <xsl:template match="rdf:type[@*:resource = 'http://www.w3.org/2002/07/owl#AsymmetricProperty']">
        <xsl:value-of select="f:getDescriptionLabel('asymmetric')" />
    </xsl:template>
    
    <xsl:template match="rdf:type[@*:resource = 'http://www.w3.org/2002/07/owl#TransitiveProperty']">
        <xsl:value-of select="f:getDescriptionLabel('transitive')" />
    </xsl:template>
    
    <xsl:template match="owl:hasValue">
        <xsl:call-template name="get.cardinality.formula">
            <xsl:with-param name="type" select="'namedindividual'" tunnel="yes" />
            <xsl:with-param name="op" select="'value'" as="xs:string" />
        </xsl:call-template>
    </xsl:template>
    
    <xsl:template match="owl:cardinality | owl:qualifiedCardinality">
        <xsl:call-template name="get.cardinality.formula">
            <xsl:with-param name="op" select="'exactly'" as="xs:string" />
        </xsl:call-template>
    </xsl:template>
    
    <xsl:template match="owl:maxCardinality | owl:maxQualifiedCardinality">
        <xsl:call-template name="get.cardinality.formula">
            <xsl:with-param name="op" select="'max'" as="xs:string" />
        </xsl:call-template>
    </xsl:template>
    
    <xsl:template match="owl:minCardinality | owl:minQualifiedCardinality">
        <xsl:call-template name="get.cardinality.formula">
            <xsl:with-param name="op" select="'min'" as="xs:string" />
        </xsl:call-template>
    </xsl:template>
    
    <xsl:template name="get.cardinality.formula">
        <xsl:param name="op" as="xs:string" />
        <xsl:text> </xsl:text>
        <span class="logic"><xsl:value-of select="$op" /></span>
        <xsl:text> </xsl:text>
        <xsl:choose>
            <xsl:when test="@*:resource">
                <xsl:apply-templates select="@*:resource" />
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="." />
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <xsl:template match="owl:onClass">
        <xsl:text> </xsl:text>
        <xsl:apply-templates select="@*:resource">
            <xsl:with-param name="type" as="xs:string" tunnel="yes" select="'class'" />
        </xsl:apply-templates>
    </xsl:template>
    
    <xsl:template match="owl:onProperty">
        <xsl:apply-templates select="@*:resource|rdf:Description/owl:inverseOf">
            <xsl:with-param name="type" as="xs:string" tunnel="yes" select="'property'" />
        </xsl:apply-templates>
    </xsl:template>
    
    <xsl:template match="owl:allValuesFrom | owl:someValuesFrom">
        <xsl:variable name="logic" select="if (self::owl:allValuesFrom) then 'only' else 'some'" as="xs:string" />
        <xsl:text> </xsl:text>
        <span class="logic"><xsl:value-of select="$logic" /></span>
        <xsl:text> </xsl:text>
        <xsl:choose>
            <xsl:when test="exists(@*:resource)">
                <xsl:apply-templates select="@*:resource" />
            </xsl:when>
            <xsl:otherwise>
                <xsl:apply-templates />
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <xsl:template match="rdf:Description">
        <xsl:apply-templates select="@*:about|@*:ID" />
    </xsl:template>
    
    <xsl:template match="owl:intersectionOf">
        <xsl:call-template name="get.logical.formula">
            <xsl:with-param name="op" select="'and'" as="xs:string" />
        </xsl:call-template>
    </xsl:template>
    
    <xsl:template match="owl:unionOf">
        <xsl:call-template name="get.logical.formula">
            <xsl:with-param name="op" select="'or'" as="xs:string" />
        </xsl:call-template>
    </xsl:template>
    
    <xsl:template match="owl:complementOf">
        <span class="logic">not</span>
        <xsl:text> (</xsl:text>
        <xsl:apply-templates select="element() | @*:resource" />
        <xsl:text>)</xsl:text>
    </xsl:template>
    
    <xsl:template name="get.logical.formula">
        <xsl:param name="op" as="xs:string" />
        <xsl:for-each select="element()">
            <xsl:choose>
                <xsl:when test="self::rdf:Description">
                    <xsl:apply-templates select="." />
                </xsl:when>
                <xsl:otherwise>
                    <xsl:text>(</xsl:text>
                    <xsl:apply-templates select="." />
                    <xsl:text>)</xsl:text>
                </xsl:otherwise>
            </xsl:choose>
            
            <xsl:if test="position() != last()">
                <xsl:text> </xsl:text>
                <span class="logic"><xsl:value-of select="$op" /></span>
                <xsl:text> </xsl:text>
            </xsl:if>
        </xsl:for-each>
    </xsl:template>
    
    <xsl:template name="get.entity.metadata">
        <xsl:call-template name="get.entity.url" />
        <xsl:call-template name="get.version" />
        <xsl:call-template name="get.author" />
        <xsl:call-template name="get.original.source" />
    </xsl:template>
    
    <xsl:template name="get.original.source">
        <xsl:if test="exists(rdfs:isDefinedBy)">
            <dl class="definedBy">
                <dt><xsl:value-of select="f:getDescriptionLabel('isdefinedby')" /></dt>
                <xsl:for-each select="rdfs:isDefinedBy">
                    <dd>
                        <xsl:choose>
                            <xsl:when test="normalize-space(@*:resource) = ''">
                                <xsl:value-of select="$ontology-url" />
                            </xsl:when>
                            <xsl:otherwise>
                                <a href="{@*:resource}">
                                    <xsl:value-of select="@*:resource" />
                                </a>
                            </xsl:otherwise>
                        </xsl:choose>
                    </dd>
                </xsl:for-each>
            </dl>
        </xsl:if>
    </xsl:template>
    
    <xsl:template name="get.class.description">
        <xsl:if test="exists(rdfs:subClassOf | owl:hasKey) or f:hasDisjoints(.) or f:hasMembers(.) or f:hasSubclasses(.) or f:isInDomain(.) or f:isInRange(.) or f:hasEquivalent(.) or f:hasSameAs(.) or f:hasPunning(.)">
            <dl class="description">
                <xsl:call-template name="get.class.equivalent" />
                <xsl:call-template name="get.class.superclasses" />
                <xsl:call-template name="get.class.subclasses" />
                <xsl:call-template name="get.class.indomain" />
                <xsl:call-template name="get.class.inrange" />
                <xsl:call-template name="get.class.members" />
                <xsl:call-template name="get.class.keys" />
                <xsl:call-template name="get.entity.sameas">
                    <xsl:with-param name="type" select="'class'" tunnel="yes" />
                </xsl:call-template>
                <xsl:call-template name="get.entity.disjoint">
                    <xsl:with-param name="type" select="'class'" tunnel="yes" />
                </xsl:call-template>
                <xsl:call-template name="get.entity.punning" />
            </dl>
        </xsl:if>
    </xsl:template>
    
    <xsl:template name="get.individual.description">
        <xsl:variable name="hasAssertions" select="some $el in element() satisfies (some $prop in (/rdf:RDF/(owl:ObjectProperty|owl:DatatypeProperty)/(@*:about|@*:ID)) satisfies $prop = concat(namespace-uri($el),local-name($el)))" as="xs:boolean" />
        <xsl:if test="exists(rdf:type) or f:hasDisjoints(.) or f:hasSameAs(.) or $hasAssertions or f:hasPunning(.)">
            <dl class="description">
                <xsl:call-template name="get.entity.type" />
                <xsl:call-template name="get.entity.sameas">
                    <xsl:with-param name="type" select="'namedindividual'" tunnel="yes" />
                </xsl:call-template>
                <xsl:call-template name="get.entity.disjoint">
                    <xsl:with-param name="type" select="'namedindividual'" tunnel="yes" />
                </xsl:call-template>
                <xsl:call-template name="get.individual.assertions">
                    <xsl:with-param name="type" select="'namedindividual'" tunnel="yes" />
                </xsl:call-template>
                <xsl:call-template name="get.entity.punning" />
            </dl>
        </xsl:if>
    </xsl:template>
    
    <xsl:template name="get.entity.type">
        <xsl:if test="exists(rdf:type)">
            <dt><xsl:value-of select="f:getDescriptionLabel('belongsto')" /></dt>
            <xsl:apply-templates select="rdf:type">
                <xsl:with-param name="type" tunnel="yes" select="'class'" as="xs:string" />
            </xsl:apply-templates>
        </xsl:if>
    </xsl:template>
    
    <xsl:template name="get.entity.sameas">
        <xsl:variable name="currentSameAs" select="f:getSameAs(.)" as="attribute()*" />
        <xsl:if test="exists($currentSameAs)">
            <dt><xsl:value-of select="f:getDescriptionLabel('issameas')" /></dt>
            <dd>
                <xsl:for-each select="$currentSameAs">
                    <xsl:apply-templates select="." />
                    <xsl:if test="position() != last()">
                        <xsl:text>, </xsl:text>
                    </xsl:if>
                </xsl:for-each>
            </dd>
        </xsl:if>
    </xsl:template>
    
    <xsl:template name="get.entity.punning">
        <xsl:variable name="iri" select="@*:about|@*:ID" as="xs:string" />
        <xsl:variable name="type" select="f:getType(.)" as="xs:string" />
        <xsl:variable name="punningsequence" select="/rdf:RDF/element()[@*:about = $iri or @*:ID = $iri][f:getType(.) != $type]" as="element()*" />
        
        <xsl:if test="$punningsequence">
            <dt><xsl:value-of select="f:getDescriptionLabel('isalsodefinedas')" /></dt>
            <dd>
                <xsl:for-each select="$punningsequence">
                    <xsl:choose>
                        <xsl:when test="element()">
                            <a href="#{generate-id(.)}"><xsl:value-of select="f:getType(.)" /></a>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:value-of select="f:getType(.)" />
                        </xsl:otherwise>
                    </xsl:choose>
                    <xsl:if test="position() != last()">
                        <xsl:text>, </xsl:text>
                    </xsl:if>
                </xsl:for-each>
            </dd>
        </xsl:if> 
    </xsl:template>
    
    <xsl:function name="f:checkPunning" as="xs:boolean">
        <xsl:param name="el" as="element()" />
        <xsl:variable name="iri" select="$el/@*:about|$el/@*:ID" as="xs:string" />
        <xsl:variable name="type" select="f:getType($el)" as="xs:string" />
        
        <xsl:value-of select="some $other in $root/rdf:RDF/element()[@*:about = $iri or @*:ID = $iri] satisfies f:getType($other) != $type" />
    </xsl:function>
    
    <xsl:template name="get.individual.assertions">
        <xsl:variable name="assertions">
            <assertions>
                <xsl:for-each select="element()">
                    <xsl:variable name="currentURI" select="concat(namespace-uri(.),local-name(.))" as="xs:string" />
                    <xsl:if test="some $prop in (/rdf:RDF/(owl:ObjectProperty|owl:DatatypeProperty)/(@*:about|@*:ID)) satisfies $prop = $currentURI">
                        <assertion rdf:about="{$currentURI}">
                            <xsl:choose>
                                <xsl:when test="@*:resource">
                                    <xsl:attribute name="rdf:resource" select="@*:resource" />
                                </xsl:when>
                                <xsl:otherwise>
                                    <xsl:if test="@xml:lang">
                                        <xsl:attribute name="xml:lang" select="@xml:lang" />
                                    </xsl:if>
                                    <xsl:if test="@*:datatype">
                                        <xsl:attribute name="rdf:datatype" select="@*:datatype" />
                                    </xsl:if>
                                    <xsl:apply-templates />
                                </xsl:otherwise>
                            </xsl:choose>
                        </assertion>
                    </xsl:if>
                </xsl:for-each>
            </assertions>
        </xsl:variable>
        <xsl:if test="$assertions//@*:about">
            <dt><xsl:value-of select="f:getDescriptionLabel('individualassertions')" /></dt>
            <xsl:for-each select="$assertions//element()[@*:about]">
                <dd>
                    <xsl:apply-templates select="@*:about">
                        <xsl:with-param name="type" select="'property'" tunnel="yes" />
                    </xsl:apply-templates>
                    <xsl:text> </xsl:text>
                    <xsl:choose>
                        <xsl:when test="@*:resource">
                            <xsl:apply-templates select="@*:resource" />
                        </xsl:when>
                        <xsl:otherwise>
                            <span class="literal">
                                <xsl:text>"</xsl:text>
                                <xsl:value-of select="." />
                                <xsl:text>"</xsl:text>
                                <xsl:choose>
                                    <xsl:when test="@*:datatype">
                                        <xsl:text>^^</xsl:text>
                                        <xsl:apply-templates select="@*:datatype" />
                                    </xsl:when>
                                    <xsl:when test="@xml:lang">
                                        <xsl:text>@</xsl:text>
                                        <xsl:value-of select="@xml:lang" />
                                    </xsl:when>
                                </xsl:choose>
                            </span>
                        </xsl:otherwise>
                    </xsl:choose>
                </dd>
            </xsl:for-each>
        </xsl:if>
    </xsl:template>
    
    <xsl:template name="get.entity.disjoint">
        <xsl:variable name="currentDisjoints" select="f:getDisjoints(.)" as="attribute()*" />
        <xsl:if test="exists($currentDisjoints)">
            <dt><xsl:value-of select="f:getDescriptionLabel('isdisjointwith')" /></dt>
            <dd>
                <xsl:for-each select="$currentDisjoints">
                    <xsl:apply-templates select="." />
                    <xsl:if test="position() != last()">
                        <xsl:text>, </xsl:text>
                    </xsl:if>
                </xsl:for-each>
            </dd>
        </xsl:if>
    </xsl:template>
    
    <xsl:template name="get.class.keys">
        <xsl:if test="exists(owl:hasKey)">
            <dt><xsl:value-of select="f:getDescriptionLabel('haskeys')" /></dt>
            <xsl:apply-templates select="owl:hasKey" />
        </xsl:if>
    </xsl:template>
    
    <xsl:template name="get.class.equivalent">
        <xsl:if test="exists(owl:equivalentClass)">
            <dt><xsl:value-of select="f:getDescriptionLabel('isequivalentto')" /></dt>
            <xsl:apply-templates select="owl:equivalentClass" />
        </xsl:if>
    </xsl:template>
    
    <xsl:template name="get.class.superclasses">
        <xsl:if test="exists(rdfs:subClassOf)">
            <dt><xsl:value-of select="f:getDescriptionLabel('hassuperclasses')" /></dt>
            <xsl:apply-templates select="rdfs:subClassOf" />
        </xsl:if>
    </xsl:template>
    
    <xsl:template name="get.class.subclasses">
        <xsl:variable name="about" select="@*:about|@*:ID" as="xs:string" />
        <xsl:variable name="sub-classes" as="attribute()*" select="/rdf:RDF/owl:Class[some $res in rdfs:subClassOf/@*:resource satisfies $res = $about]/(@*:about|@*:ID)" />
        <xsl:if test="exists($sub-classes)">
            <dt><xsl:value-of select="f:getDescriptionLabel('hassubclasses')" /></dt>
            <dd>
                <xsl:for-each select="$sub-classes">
                    <xsl:sort select="f:getLabel(.)" data-type="text" order="ascending" />
                    <xsl:apply-templates select="." />
                    <xsl:if test="position() != last()">
                        <xsl:text>, </xsl:text>
                    </xsl:if>
                </xsl:for-each>
            </dd>
        </xsl:if>
    </xsl:template>
    
    <xsl:template name="get.class.indomain">
        <xsl:variable name="about" select="@*:about|@*:ID" as="xs:string" />
        <xsl:variable name="properties" as="attribute()*" select="/rdf:RDF/(owl:ObjectProperty|owl:DatatypeProperty|owl:AnnotationProperty)[some $res in rdfs:domain/@*:resource satisfies $res = $about]/(@*:about|@*:ID)" />
        <xsl:if test="exists($properties)">
            <dt><xsl:value-of select="f:getDescriptionLabel('isindomainof')" /></dt>
            <dd>
                <xsl:for-each select="$properties">
                    <xsl:sort select="f:getLabel(.)" order="ascending" data-type="text" />
                    <xsl:apply-templates select=".">
                        <xsl:with-param name="type" as="xs:string" tunnel="yes" select="if (../owl:AnnotationProperty) then 'annotation' else 'property'" />
                    </xsl:apply-templates>
                    <xsl:if test="position() != last()">
                        <xsl:text>, </xsl:text>
                    </xsl:if>
                </xsl:for-each>
            </dd>
        </xsl:if>
    </xsl:template>
    
    <xsl:template name="get.class.inrange">
        <xsl:variable name="about" select="(@*:about|@*:ID)" as="xs:string" />
        <xsl:variable name="properties" as="attribute()*" select="/rdf:RDF/(owl:ObjectProperty|owl:DatatypeProperty|owl:AnnotationProperty)[some $res in rdfs:range/@*:resource satisfies $res = $about]/(@*:about|@*:ID)" />
        <xsl:if test="exists($properties)">
            <dt><xsl:value-of select="f:getDescriptionLabel('isinrangeof')" /></dt>
            <dd>
                <xsl:for-each select="$properties">
                    <xsl:sort select="f:getLabel(.)" order="ascending" data-type="text" />
                    <xsl:apply-templates select=".">
                        <xsl:with-param name="type" as="xs:string" tunnel="yes" select="if (../owl:AnnotationProperty) then 'annotation' else 'property'" />
                    </xsl:apply-templates>
                    <xsl:if test="position() != last()">
                        <xsl:text>, </xsl:text>
                    </xsl:if>
                </xsl:for-each>
            </dd>
        </xsl:if>
    </xsl:template>
    
    <xsl:template name="get.class.members">
        <xsl:variable name="about" select="(@*:about|@*:ID)" as="xs:string" />
        <xsl:variable name="members" as="attribute()*" select="/rdf:RDF/owl:NamedIndividual[some $res in rdf:type/@*:resource satisfies $res = $about]/(@*:about|@*:ID)" />
        <xsl:if test="exists($members)">
            <dt><xsl:value-of select="f:getDescriptionLabel('hasmembers')" /></dt>
            <dd>
                <xsl:for-each select="$members">
                    <xsl:sort select="f:getLabel(.)" order="ascending" data-type="text" />
                    <xsl:apply-templates select=".">
                        <xsl:with-param name="type" as="xs:string" tunnel="yes" select="'individual'" />
                    </xsl:apply-templates>
                    <xsl:if test="position() != last()">
                        <xsl:text>, </xsl:text>
                    </xsl:if>
                </xsl:for-each>
            </dd>
        </xsl:if>
    </xsl:template>
    
    <xsl:template name="get.property.description">
        <xsl:if test="exists(rdfs:subPropertyOf | rdfs:domain | rdfs:range | owl:propertyChainAxiom) or f:hasSubproperties(.) or f:hasInverseOf(.) or f:hasDisjoints(.) or f:hasEquivalent(.) or f:hasSameAs(.) or f:hasPunning(.)">
            <div class="description">
                <xsl:call-template name="get.characteristics" />
                <dl>
                    <xsl:call-template name="get.property.equivalentproperty" />
                    <xsl:call-template name="get.property.superproperty" />
                    <xsl:call-template name="get.property.subproperty" />
                    <xsl:call-template name="get.property.domain" />
                    <xsl:call-template name="get.property.range" />
                    <xsl:call-template name="get.property.inverse">
                        <xsl:with-param name="type" select="'property'" tunnel="yes" as="xs:string" />
                    </xsl:call-template>
                    <xsl:call-template name="get.property.chain" />
                    <xsl:call-template name="get.entity.sameas">
                        <xsl:with-param name="type" select="'property'" tunnel="yes" as="xs:string" />
                    </xsl:call-template>
                    <xsl:call-template name="get.entity.disjoint">
                        <xsl:with-param name="type" select="'property'" tunnel="yes" as="xs:string" />
                    </xsl:call-template>
                    <xsl:call-template name="get.entity.punning" />
                </dl>
            </div>
        </xsl:if>
    </xsl:template>
    
    <xsl:template name="get.property.inverse">
        <xsl:variable name="currentInverseOf" select="f:getInverseOf(.)" as="attribute()*" />
        <xsl:if test="exists($currentInverseOf)">
            <dt><xsl:value-of select="f:getDescriptionLabel('isinverseof')" /></dt>
            <dd>
                <xsl:for-each select="$currentInverseOf">
                    <xsl:apply-templates select="." />
                    <xsl:if test="position() != last()">
                        <xsl:text>, </xsl:text>
                    </xsl:if>
                </xsl:for-each>
            </dd>
        </xsl:if>
    </xsl:template>
    
    <xsl:template name="get.property.chain">
        <xsl:if test="exists(owl:propertyChainAxiom)">
            <dt><xsl:value-of select="f:getDescriptionLabel('hassubpropertychains')" /></dt>
            <xsl:apply-templates select="owl:propertyChainAxiom" />
        </xsl:if>
    </xsl:template>
    
    <xsl:template name="get.property.equivalentproperty">
        <xsl:variable name="currentEquivalent" select="f:getEquivalent(.)" as="attribute()*" />
        <xsl:if test="exists($currentEquivalent)">
            <dt><xsl:value-of select="f:getDescriptionLabel('hasequivalentproperties')" /></dt>
            <dd>
                <xsl:for-each select="$currentEquivalent">
                    <xsl:apply-templates select="." />
                    <xsl:if test="position() != last()">
                        <xsl:text>, </xsl:text>
                    </xsl:if>
                </xsl:for-each>
            </dd>
        </xsl:if>
    </xsl:template>
    
    <xsl:template name="get.property.superproperty">
        <xsl:if test="exists(rdfs:subPropertyOf)">
            <dt><xsl:value-of select="f:getDescriptionLabel('hassuperproperties')" /></dt>
            <xsl:apply-templates select="rdfs:subPropertyOf" />
        </xsl:if>
    </xsl:template>
    
    <xsl:template name="get.property.subproperty">
        <xsl:variable name="type" select="if (self::owl:AnnotationProperty) then 'annotation' else 'property'" as="xs:string" />
        <xsl:variable name="about" select="(@*:about|@*:ID)" as="xs:string" />
        <xsl:variable name="sub-properties" as="attribute()*" select="/rdf:RDF/(if ($type = 'property') then owl:DatatypeProperty | owl:ObjectProperty else owl:AnnotationProperty)[some $res in rdfs:subPropertyOf/@*:resource satisfies $res = $about]/(@*:about|@*:ID)" />
        <xsl:if test="exists($sub-properties)">
            <dt><xsl:value-of select="f:getDescriptionLabel('hassubproperties')" /></dt>
            <dd>
                <xsl:for-each select="$sub-properties">
                    <xsl:sort select="f:getLabel(.)" data-type="text" order="ascending" />
                    <xsl:apply-templates select="." />
                    <xsl:if test="position() != last()">
                        <xsl:text>, </xsl:text>
                    </xsl:if>
                </xsl:for-each>
            </dd>
        </xsl:if>
    </xsl:template>
    
    <xsl:template name="get.property.domain">
        <xsl:if test="exists(rdfs:domain)">
            <dt><xsl:value-of select="f:getDescriptionLabel('hasdomain')" /></dt>
            <xsl:apply-templates select="rdfs:domain" />
        </xsl:if>
    </xsl:template>
    
    <xsl:template name="get.property.range">
        <xsl:if test="exists(rdfs:range)">
            <dt><xsl:value-of select="f:getDescriptionLabel('hasrange')" /></dt>
            <xsl:apply-templates select="rdfs:range" />
        </xsl:if>
    </xsl:template>
    
    <xsl:template name="get.content">
    	<span class="markdown">
    		<xsl:value-of select="text()" />
    	</span>
    	<!-- 
        <xsl:for-each select="text()">
            <xsl:for-each select="tokenize(.,$n)">
                <xsl:if test="normalize-space(.) != ''">
                    <p>
                    	<xsl:variable name="withLinks" select="replace(.,'\[\[([^\[\]]+)\]\[([^\[\]]+)\]\]','@@@$1@@$2@@@')" />
                    	<xsl:for-each select="tokenize($withLinks,'@@@')">
                    		<xsl:choose>
                    			<xsl:when test="matches(.,'@@')">
                    				<xsl:variable name="tokens" select="tokenize(.,'@@')" />
                    				<a href="{$tokens[1]}"><xsl:value-of select="$tokens[2]" /></a>
                    			</xsl:when>
                    			<xsl:otherwise>
                    				<xsl:value-of select="." />
                    			</xsl:otherwise>
                    		</xsl:choose>
                    	</xsl:for-each>
                    </p>
                </xsl:if>
            </xsl:for-each>
        </xsl:for-each>
         -->
    </xsl:template>
    
    <xsl:template name="get.title">
        <xsl:for-each select="tokenize(.//text(),$n)">
            <xsl:value-of select="." />
            <xsl:if test="position() != last()">
                <br />
            </xsl:if>
        </xsl:for-each>
    </xsl:template>
    
    <xsl:template name="get.ontology.url">
        <xsl:if test="exists((@*:about|@*:ID)[normalize-space() != ''])">
            <dl>
                <dt>IRI:</dt>
                <dd><xsl:value-of select="@*:about|@*:ID" /></dd>
                <xsl:if test="exists(owl:versionIRI)">
                    <dt>Version IRI:</dt>
                    <dd><xsl:value-of select="owl:versionIRI/@*:resource" /></dd>
                </xsl:if>
            </dl>
        </xsl:if>
    </xsl:template>
    
    <xsl:template name="get.version">
        <xsl:if test="exists(owl:versionInfo | owl:priorVersion | owl:backwardCompatibleWith | owl:incompatibleWith | dc:date | dcterms:date)">
            <dl>
                <xsl:apply-templates select="dc:date | dcterms:date" />
                <xsl:apply-templates select="owl:versionInfo" />
                <xsl:apply-templates select="owl:priorVersion" />
                <xsl:apply-templates select="owl:backwardCompatibleWith" />
                <xsl:apply-templates select="owl:incompatibleWith" />
            </dl>
        </xsl:if>
    </xsl:template>
    
    <xsl:template name="get.imports">
        <xsl:if test="exists(owl:imports)">
            <dl>
                <dt><xsl:value-of select="f:getDescriptionLabel('importedontologies')" />:</dt>
                <xsl:apply-templates select="owl:imports" />
            </dl>
        </xsl:if>
    </xsl:template>
    
    <xsl:template name="get.entity.name">
    	<xsl:variable name="url" select="@*:about|@*:ID" as="xs:string" />
        <a name="{$url}" />
        <xsl:if test="starts-with($url, if (ends-with($ontology-url,'#')) then $ontology-url else concat($ontology-url, '#'))">
        	<a name="{substring-after($url, '#')}" />
        </xsl:if>
        <xsl:choose>
            <xsl:when test="exists(rdfs:label)">
                <xsl:apply-templates select="rdfs:label" />
            </xsl:when>
            <xsl:otherwise>
                <h3>
                    <xsl:value-of select="f:getLabel(@*:about|@*:ID)" />
                    <xsl:call-template name="get.entity.type.descriptor">
                        <xsl:with-param name="iri" select="@*:about|@*:ID" as="xs:string" />
                    </xsl:call-template>
                </h3>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <xsl:template name="get.author">
        <xsl:if test="exists(dc:creator | dc:contributor | dcterms:creator[ancestor::owl:Ontology] | dcterms:contributor[ancestor::owl:Ontology])">
            <dl>
                <xsl:if test="exists(dc:creator|dcterms:creator[ancestor::owl:Ontology])">
                    <dt><xsl:value-of select="f:getDescriptionLabel('authors')" />:</dt>
                    <xsl:apply-templates select="dc:creator|dcterms:creator[ancestor::owl:Ontology]">
                        <xsl:sort select="text()|@*:resource" data-type="text" order="ascending" />
                    </xsl:apply-templates>
                </xsl:if>
                <xsl:if test="exists(dc:contributor|dcterms:contributor[ancestor::owl:Ontology])">
                    <dt><xsl:value-of select="f:getDescriptionLabel('contributors')" />:</dt>
                    <xsl:apply-templates select="dc:contributor|dcterms:contributor[ancestor::owl:Ontology]">
                        <xsl:sort select="text()|@*:resource" data-type="text" order="ascending" />
                    </xsl:apply-templates>
                </xsl:if>
            </dl>
        </xsl:if>
    </xsl:template>
    
    <xsl:template name="get.publisher">
        <xsl:if test="exists(dc:publisher | dcterms:publisher)">
            <dl>
                <dt><xsl:value-of select="f:getDescriptionLabel('publisher')" />:</dt>
                <xsl:apply-templates select="dc:publisher|dcterms:publisher">
                    <xsl:sort select="text()|@*:resource" data-type="text" order="ascending" />
                </xsl:apply-templates>
            </dl>
        </xsl:if>
    </xsl:template>

    <xsl:template name="get.toc">
        <div id="toc">
            <h2><xsl:value-of select="f:getDescriptionLabel('toc')" /></h2>
            <ol>
                <xsl:if test="exists(//owl:Ontology/dc:description[normalize-space() != ''])">
                    <li><a href="#introduction"><xsl:value-of select="f:getDescriptionLabel('introduction')" /></a></li>
                </xsl:if>
                <xsl:if test="exists(/rdf:RDF/owl:Class/element())">
                    <li><a href="#classes"><xsl:value-of select="f:getDescriptionLabel('classes')" /></a></li>
                </xsl:if>
                <xsl:if test="exists(//owl:ObjectProperty/element())">
                    <li><a href="#objectproperties"><xsl:value-of select="f:getDescriptionLabel('objectproperties')" /></a></li>
                </xsl:if>
                <xsl:if test="exists(//owl:DatatypeProperty/element())">
                    <li><a href="#dataproperties"><xsl:value-of select="f:getDescriptionLabel('dataproperties')" /></a></li>
                </xsl:if>
                <xsl:if test="exists(//owl:NamedIndividual/element())">
                    <li><a href="#namedindividuals"><xsl:value-of select="f:getDescriptionLabel('namedindividuals')" /></a></li>
                </xsl:if>
                <xsl:if test="exists(//owl:AnnotationProperty)">
                    <li><a href="#annotationproperties"><xsl:value-of select="f:getDescriptionLabel('annotationproperties')" /></a></li>
                </xsl:if>
                <xsl:if test="exists(//rdf:Description[exists(rdf:type[@*:resource = 'http://www.w3.org/2002/07/owl#AllDisjointClasses'])]) or exists(/rdf:RDF/(owl:Class|owl:Restriction)[empty(@*:about | @*:ID) and exists(rdfs:subClassOf|owl:equivalentClass)])">
                    <li><a href="#generalaxioms"><xsl:value-of select="f:getDescriptionLabel('generalaxioms')" /></a></li>
                </xsl:if>
                <xsl:if test="exists(/rdf:RDF/(swrl:Imp | rdf:Description[rdf:type[@*:resource = 'http://www.w3.org/2003/11/swrl#Imp']]))">
                    <li><a href="#swrlrules"><xsl:value-of select="f:getDescriptionLabel('rules')" /></a></li>
                </xsl:if>
                <li><a href="#namespacedeclarations"><xsl:value-of select="f:getDescriptionLabel('namespaces')" /></a></li>
            </ol>
        </div>
    </xsl:template>

    <xsl:template name="get.entity.url">
        <p>
            <strong>IRI:</strong>
            <xsl:text> </xsl:text>
            <xsl:value-of select="@*:about|@*:ID" />
        </p>
    </xsl:template>
    
    <xsl:template name="get.generalaxioms">
        <xsl:if test="exists(/rdf:RDF/rdf:Description[exists(rdf:type[@*:resource = 'http://www.w3.org/2002/07/owl#AllDisjointClasses'])]) or exists(/rdf:RDF/(owl:Class|owl:Restriction)[empty(@*:ID | @*:about) and exists(rdfs:subClassOf|owl:equivalentClass)])">
            <div id="generalaxioms">
                <h2><xsl:value-of select="f:getDescriptionLabel('generalaxioms')" /></h2>
                <xsl:apply-templates select="/rdf:RDF/(rdf:Description[exists(rdf:type[@*:resource = 'http://www.w3.org/2002/07/owl#AllDisjointClasses'])]|(owl:Class|owl:Restriction)[empty(@*:ID | @*:about) and exists(rdfs:subClassOf|owl:equivalentClass)])" />
            </div>
        </xsl:if>
    </xsl:template>
    
    <xsl:template name="get.namespacedeclarations">
        <div id="namespacedeclarations">
            <h2>
                <xsl:value-of select="f:getDescriptionLabel('namespaces')" /><xsl:text> </xsl:text>
            </h2>
            <dl>
                <xsl:for-each select="distinct-values($prefixes-uris[position() mod 2 = 1])">
                    <xsl:sort select="." data-type="text" order="ascending" />
                    <xsl:variable name="prefix" select="." />
                    <xsl:if test=". != 'xml'">
                        <dt>
                            <xsl:choose>
                                <xsl:when test="$prefix = ''">
                                    <em><xsl:value-of select="f:getDescriptionLabel('namespace')" /></em>
                                </xsl:when>
                                <xsl:otherwise>
                                    <xsl:value-of select="$prefix" />
                                </xsl:otherwise>
                            </xsl:choose>
                        </dt>
                        <dd>
                            <xsl:value-of select="$prefixes-uris[index-of($prefixes-uris,$prefix)[1] + 1]" />
                        </dd>
                    </xsl:if>
                </xsl:for-each>
            </dl>
        </div>
    </xsl:template>
    
    <xsl:template name="get.classes">
        <xsl:if test="exists(/rdf:RDF/owl:Class/element())">
            <div id="classes">
                <h2><xsl:value-of select="f:getDescriptionLabel('classes')" /></h2>
                <xsl:call-template name="get.classes.toc" />
                <xsl:apply-templates select="/rdf:RDF/owl:Class[exists(element()) and exists(@*:about|@*:ID)]">
                    <xsl:sort select="lower-case(f:getLabel(@*:about|@*:ID))"
                        order="ascending" data-type="text" />
                    <xsl:with-param name="type" tunnel="yes" as="xs:string" select="'class'" />
                </xsl:apply-templates>
            </div>
        </xsl:if>
    </xsl:template>
    
    <xsl:template name="get.classes.toc">
        <ul class="hlist">
            <xsl:apply-templates select="/rdf:RDF/owl:Class[exists(element()) and exists(@*:about|@*:ID)]" mode="toc">
                <xsl:sort select="lower-case(f:getLabel(@*:about|@*:ID))"
                    order="ascending" data-type="text" />
                <xsl:with-param name="type" tunnel="yes" as="xs:string" select="'class'" />
            </xsl:apply-templates>
        </ul>
    </xsl:template>
    
    <xsl:template name="get.namedindividuals">
        <xsl:if test="exists(//owl:NamedIndividual/element())">
            <div id="namedindividuals">
                <h2><xsl:value-of select="f:getDescriptionLabel('namedindividuals')" /></h2>
                <xsl:call-template name="get.namedindividuals.toc" />
                <xsl:apply-templates select="/rdf:RDF/owl:NamedIndividual[exists(element())]">
                    <xsl:sort select="lower-case(f:getLabel(@*:about|@*:ID))"
                        order="ascending" data-type="text" />
                    <xsl:with-param name="type" tunnel="yes" as="xs:string" select="'individual'" />
                </xsl:apply-templates>
            </div>
        </xsl:if>
    </xsl:template>
    
    <xsl:template name="get.namedindividuals.toc">
        <ul class="hlist">
            <xsl:apply-templates select="/rdf:RDF/owl:NamedIndividual[exists(element())]" mode="toc">
                <xsl:sort select="lower-case(f:getLabel(@*:about|@*:ID))"
                    order="ascending" data-type="text" />
                <xsl:with-param name="type" tunnel="yes" as="xs:string" select="'individual'" />
            </xsl:apply-templates>
        </ul>
    </xsl:template>
    
    <xsl:template name="get.objectproperties">
        <xsl:if test="exists(//owl:ObjectProperty/element())">
            <div id="objectproperties">
                <h2><xsl:value-of select="f:getDescriptionLabel('objectproperties')" /></h2>
                <xsl:call-template name="get.objectproperties.toc" />
                <xsl:apply-templates select="/rdf:RDF/owl:ObjectProperty[exists(element())]">
                    <xsl:sort select="lower-case(f:getLabel(@*:about|@*:ID))"
                        order="ascending" data-type="text" />
                    <xsl:with-param name="type" tunnel="yes" as="xs:string" select="'property'" />
                </xsl:apply-templates>
            </div>
        </xsl:if>
    </xsl:template>
    
    <xsl:template name="get.objectproperties.toc">
        <ul class="hlist">
            <xsl:apply-templates select="/rdf:RDF/owl:ObjectProperty[exists(element())]" mode="toc">
                <xsl:sort select="lower-case(f:getLabel(@*:about|@*:ID))"
                    order="ascending" data-type="text" />
                <xsl:with-param name="type" tunnel="yes" as="xs:string" select="'annotation'" />
            </xsl:apply-templates>
        </ul>
    </xsl:template>
    
    <xsl:template name="get.annotationproperties">
        <xsl:if test="exists(//owl:AnnotationProperty)">
            <div id="annotationproperties">
                <h2><xsl:value-of select="f:getDescriptionLabel('annotationproperties')" /></h2>
                <xsl:call-template name="get.annotationproperties.toc" />
                <xsl:apply-templates select="/rdf:RDF/owl:AnnotationProperty">
                    <xsl:sort select="lower-case(f:getLabel(@*:about|@*:ID))"
                        order="ascending" data-type="text" />
                    <xsl:with-param name="type" tunnel="yes" as="xs:string" select="'annotation'" />
                </xsl:apply-templates>
            </div>
        </xsl:if>
    </xsl:template>
    
    <xsl:template name="get.annotationproperties.toc">
        <ul class="hlist">
            <xsl:apply-templates select="/rdf:RDF/owl:AnnotationProperty" mode="toc">
                <xsl:sort select="lower-case(f:getLabel(@*:about|@*:ID))"
                    order="ascending" data-type="text" />
                <xsl:with-param name="type" tunnel="yes" as="xs:string" select="'property'" />
            </xsl:apply-templates>
        </ul>
    </xsl:template>
    
    <xsl:template name="get.dataproperties">
        <xsl:if test="exists(//owl:DatatypeProperty/element())">
            <div id="dataproperties">
                <h2><xsl:value-of select="f:getDescriptionLabel('dataproperties')" /></h2>
                <xsl:call-template name="get.dataproperties.toc" />
                <xsl:apply-templates select="/rdf:RDF/owl:DatatypeProperty[exists(element())]">
                    <xsl:sort select="lower-case(f:getLabel(@*:about|@*:ID))"
                        order="ascending" data-type="text" />
                    <xsl:with-param name="type" tunnel="yes" as="xs:string" select="'property'" />
                </xsl:apply-templates>
            </div>
        </xsl:if>
    </xsl:template>
    
    <xsl:template name="get.dataproperties.toc">
        <ul class="hlist">
            <xsl:apply-templates select="/rdf:RDF/owl:DatatypeProperty[exists(element())]" mode="toc">
                <xsl:sort select="lower-case(f:getLabel(@*:about|@*:ID))"
                    order="ascending" data-type="text" />
                <xsl:with-param name="type" tunnel="yes" as="xs:string" select="'property'" />
            </xsl:apply-templates>
        </ul>
    </xsl:template>
    
    <xsl:template name="get.entity.type.descriptor">
        <xsl:param name="iri" as="xs:string" />
        <xsl:param name="type" as="xs:string" select="''" tunnel="yes" />
        <xsl:variable name="el" select="$root/rdf:RDF/element()[@*:about = $iri or @*:ID = $iri]" as="element()*" />
        <xsl:choose>
            <xsl:when test="($type = '' or $type = 'class') and ($el[self::owl:Class] or $iri = 'http://www.w3.org/2002/07/owl#Thing')">
                <sup title="{f:getDescriptionLabel('class')}" class="type-c">c</sup>
            </xsl:when>
            <xsl:when test="($type = '' or $type = 'property') and $el[self::owl:ObjectProperty]">
                <sup title="{f:getDescriptionLabel('objectproperty')}" class="type-op">op</sup>
            </xsl:when>
            <xsl:when test="($type = '' or $type = 'property') and $el[self::owl:DatatypeProperty]">
                <sup title="{f:getDescriptionLabel('dataproperty')}" class="type-dp">dp</sup>
            </xsl:when>
            <xsl:when test="($type = '' or $type = 'annotation') and $el[self::owl:AnnotationProperty]">
                <sup title="{f:getDescriptionLabel('annotationproperty')}" class="type-ap">ap</sup>
            </xsl:when>
            <xsl:when test="($type = '' or $type = 'individual') and $el[self::owl:NamedIndividual]">
                <sup title="{f:getDescriptionLabel('namedindividual')}" class="type-ni">ni</sup>
            </xsl:when>
        </xsl:choose>
    </xsl:template>
    

    <xsl:template name="get.characteristics">
        <xsl:variable name="nodes" select="rdf:type[some $c in ('http://www.w3.org/2002/07/owl#FunctionalProperty', 'http://www.w3.org/2002/07/owl#InverseFunctionalProperty', 'http://www.w3.org/2002/07/owl#ReflexiveProperty', 'http://www.w3.org/2002/07/owl#IrreflexiveProperty', 'http://www.w3.org/2002/07/owl#SymmetricProperty', 'http://www.w3.org/2002/07/owl#AsymmetricProperty', 'http://www.w3.org/2002/07/owl#TransitiveProperty') satisfies @*:resource = $c]" as="element()*" />
        <xsl:if test="exists($nodes)">
            <p>
                <strong><xsl:value-of select="f:getDescriptionLabel('hascharacteristics')" />:</strong>
                <xsl:text> </xsl:text>
                <xsl:for-each select="$nodes">
                    <xsl:apply-templates select="." />
                    <xsl:if test="position() != last()">
                        <xsl:text>, </xsl:text>
                    </xsl:if>
                </xsl:for-each>
            </p>
        </xsl:if>
    </xsl:template>
    
    <!--
        input: un elemento tipicamente contenente solo testo
        output: un booleano che risponde se quell'elemento è quello giusto per la lingua considerata        
    -->
    <xsl:function name="f:isInLanguage" as="xs:boolean">
        <xsl:param name="el" as="element()" />
        <xsl:variable name="isRightLang" select="$el/@xml:lang = $lang" as="xs:boolean" />
        <xsl:variable name="isDefLang" select="$el/@xml:lang = $def-lang" as="xs:boolean" />
        
        <xsl:choose>
            <!-- 
                Ritorno false se:
                - c'è qualche elemento prima di me del linguaggio giusto OR
                - io non sono del linguaggio giusto AND
                    - c'è qualche elemento dopo di me del linguaggio giusto OR
                    - c'è qualche elemento prima di me che è del linguaggio di default OR
                    - io non sono del linguaggio di default AND
                        - c'è qualche elemento dopo di me del linguaggio di default OR
                        - c'è qualche elemento prima di me
            -->
            <xsl:when test="
                (some $item in ($el/preceding-sibling::element()[name() = name($el)]) satisfies $item/@xml:lang = $lang) or
                (not($isRightLang) and
                    (
                        (some $item in ($el/following-sibling::element()[name() = name($el)]) satisfies $item/@xml:lang = $lang) or
                        (some $item in ($el/preceding-sibling::element()[name() = name($el)]) satisfies $item/@xml:lang = $def-lang) or
                        not($isDefLang) and
                            (
                                (some $item in ($el/following-sibling::element()[name() = name($el)]) satisfies $item/@xml:lang = $def-lang) or
                                exists($el/preceding-sibling::element()[name() = name($el)]))
                            ))">
                <xsl:value-of select="false()" />
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="true()" />
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>
    
    <xsl:function name="f:getPrefixFromIRI" as="xs:string?">
        <xsl:param name="iri" as="xs:string" />
        
        <xsl:if test="not(starts-with($iri,'_:'))">
            <xsl:variable name="iriNew" select="if (contains($iri,'#') or contains($iri,'/')) then $iri else concat(base-uri($root), $iri)" as="xs:string" />
            
            <xsl:variable name="ns" select="if (contains($iriNew,'#')) then substring($iriNew,1,f:string-first-index-of($iriNew,'#')) else substring($iriNew,1,f:string-last-index-of(replace($iriNew,'://','---'),'/'))" as="xs:string" />
            
            <xsl:variable name="index" select="index-of($prefixes-uris,$ns)[1]" as="xs:integer?" />
            <xsl:if test="exists($index)">
                <xsl:value-of select="$prefixes-uris[$index - 1]" />
            </xsl:if>
        </xsl:if>
    </xsl:function>
    
    <xsl:function name="f:hasSubclasses" as="xs:boolean">
        <xsl:param name="el" as="element()" />
        <xsl:value-of select="exists($rdf/owl:Class[some $res in rdfs:subClassOf/@*:resource satisfies $res = $el/(@*:about|@*:ID)])" />
    </xsl:function>
    
    <xsl:function name="f:hasMembers" as="xs:boolean">
        <xsl:param name="el" as="element()" />
        <xsl:value-of select="exists($rdf/owl:NamedIndividual[some $res in rdf:type/@*:resource satisfies $res = $el/(@*:about|@*:ID)])" />
    </xsl:function>
    
    <xsl:function name="f:isInRange" as="xs:boolean">
        <xsl:param name="el" as="element()" />
        <xsl:value-of select="exists($rdf/(owl:ObjectProperty|owl:DatatypeProperty|owl:AnnotationProperty)[some $res in rdfs:range/@*:resource satisfies $res = $el/(@*:about|@*:ID)])" />
    </xsl:function>
    
    <xsl:function name="f:isInDomain" as="xs:boolean">
        <xsl:param name="el" as="element()" />
        <xsl:value-of select="exists($rdf/(owl:ObjectProperty|owl:DatatypeProperty|owl:AnnotationProperty)[some $res in rdfs:domain/@*:resource satisfies $res = $el/(@*:about|@*:ID)])" />
    </xsl:function>
    
    <xsl:function name="f:hasSubproperties" as="xs:boolean">
        <xsl:param name="el" as="element()" />
        <xsl:variable name="type" select="if ($el/self::owl:AnnotationProperty) then 'annotation' else 'property'" as="xs:string" />
        <xsl:value-of select="exists($rdf/(if ($type = 'property') then owl:DatatypeProperty | owl:ObjectProperty else owl:AnnotationProperty)[some $res in rdfs:subPropertyOf/@*:resource satisfies $res = $el/(@*:about|@*:ID)])" />
    </xsl:function>
    
    <xsl:function name="f:getType" as="xs:string?">
        <xsl:param name="element" as="element()" />
        <xsl:variable name="type" select="local-name($element)" as="xs:string" />
        <xsl:choose>
            <xsl:when test="$type = 'Class'">
                <xsl:value-of select="f:getDescriptionLabel('class')" />
            </xsl:when>
            <xsl:when test="$type = 'ObjectProperty'">
                <xsl:value-of select="f:getDescriptionLabel('objectproperty')" />
            </xsl:when>
            <xsl:when test="$type = 'DatatypeProperty'">
                <xsl:value-of select="f:getDescriptionLabel('dataproperty')" />
            </xsl:when>
            <xsl:when test="$type = 'AnnotationProperty'">
                <xsl:value-of select="f:getDescriptionLabel('annotationproperty')" />
            </xsl:when>
            <xsl:when test="$type = 'DataRange'">
                <xsl:value-of select="f:getDescriptionLabel('datarange')" />
            </xsl:when>
            <xsl:when test="$type = 'NamedIndividual'">
                <xsl:value-of select="f:getDescriptionLabel('namedindividual')" />
            </xsl:when>
        </xsl:choose>
    </xsl:function>
    
    <xsl:function name="f:getDescriptionLabel" as="xs:string">
        <xsl:param name="inputlabel" as="xs:string" />
        <xsl:variable name="labelname" select="lower-case(replace($inputlabel,' +',''))" as="xs:string" />
        <xsl:variable name="label" as="xs:string">
            <xsl:variable name="label" select="normalize-space($labels//element()[lower-case(local-name()) = $labelname]/text())" as="xs:string?"/>
            <xsl:choose>
                <xsl:when test="$label">
                    <xsl:value-of select="$label" />
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="normalize-space($default-labels//element()[lower-case(local-name()) = $labelname]/text())" />
                </xsl:otherwise>
            </xsl:choose>            
        </xsl:variable>
        
        <xsl:choose>
            <xsl:when test="$label">
                <xsl:value-of select="$label" />
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="'[ERROR-LABEL]'" />
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>
    
    <xsl:function name="f:hasPunning" as="xs:boolean">
        <xsl:param name="el" as="element()" />
        <xsl:variable name="iri" select="$el/(@*:about|@*:ID)" as="xs:string" />
        <xsl:variable name="type" select="f:getType($el)" as="xs:string" />
        <xsl:value-of select="exists($rdf/element()[@*:about = $iri or @*:ID = $iri][f:getType(.) != $type])" />
    </xsl:function>
</xsl:stylesheet>
