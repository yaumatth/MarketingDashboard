/*

Build: unified_ads

Purpose: Unify Facebook, Google, and TikTok advertising data into a single table for cross-channel reporting in Power BI

Core schema (cross-channel KPIs that are shared/comparable across platforms):
- date, platform, campaign_id, campaign_name, ad_group_id, ad_group_name, impressions, clicks, cost, conversions
- Note: Inline comments highlight standardization of field names across files (e.g., Facebook spend -> cost)

Derived ratio fields (row-level):
- Important: Ratio fields in unified file are calculated from base metrics and used for reference only. Aggregated ratios in Power BI are computed as SUM(numerator)/SUM(denominator) which avoids the averaging of ratios.

- ctr_row = clicks / impressions
- cvr_row = conversions / clicks
- cpc_row = cost / clicks
- cpa_row = cost / conversions


Support schema (KPIs only presented on specific platforms)
- Note: For platform specific KPIs, when other platforms do not contain the metric, the fields are set to NULL.

- Facebook only KPIs: video_views, reach, frequency
- Google only: conversion_value, quality_score, search_impression_share
- TikTok only: video_views, video_watch_25, video_watch_50, video_watch_75, video_watch_100, likes, shares, comments

Omitted columns
Ratios provided by specific platforms in source files were omitted because they duplicate previous work. 
- Facebook: engagement_rate (duplicating ctr_row) was omitted.
- Google: ctr (duplicating ctr_row), and avg_cpc (duplicating ctr_row) was omitted.

*/ 


-- 1) Create the unified table
CREATE OR REPLACE TABLE unified_ads (
	-- Core schema
	date DATE,
	platform VARCHAR,
	
	campaign_id VARCHAR,
	campaign_name VARCHAR,
	
	ad_group_id VARCHAR,
	ad_group_name VARCHAR,
	
	impressions NUMBER,
	clicks NUMBER,
	cost NUMBER(18, 2),
	conversions NUMBER,
	
	-- Row level ratios

	ctr_row NUMBER(18, 6),
	cvr_row NUMBER(18, 6),
	cpc_row NUMBER(18, 6),
	cpa_row NUMBER(18, 6),

	-- Platform specific KPIs
	
	/* Facebook and TikTok */
	video_views NUMBER,
	
	/* Facebook only */
	reach NUMBER,
	frequency NUMBER(18, 2),
	
	/* Google only  */
	conversion_value NUMBER,
	quality_score NUMBER,
	search_impression_share NUMBER(18, 2),
	
	/* TikTok only */
	video_watch_25 NUMBER,
	video_watch_50 NUMBER,
	video_watch_75 NUMBER,
	video_watch_100 NUMBER,
	likes NUMBER,
	shares NUMBER,
	comments NUMBER
	
);


-- 2) Load unified data with an INSERT statement, UNION ALL for all the datasets
INSERT INTO unified_ads (
	-- Core schema
	date,
	platform,
	
	campaign_id,
	campaign_name,
	
	ad_group_id, 
	ad_group_name,
	
	impressions,
	clicks,
	cost,
	conversions,
	
	
	-- Derived ratios
	ctr_row,
	cvr_row,
	cpc_row,
	cpa_row,
	
	-- Platform specific KPIs
	video_views, -- Facebook KPIs
	reach,
	frequency,
	
	conversion_value, -- Google KPIs
	quality_score,
	search_impression_share,
	
	video_watch_25, -- TikTok KPIs
	video_watch_50,
	video_watch_75,
	video_watch_100,
	likes,
	shares,
	comments	
)

SELECT
	-- Core metrics
	date       								         						as date,
	'Facebook'																as platform,
	
	campaign_id                        										as campaign_id,
	campaign_name								                  			as campaign_name,
	
	ad_set_id                          										as ad_group_id, -- ad_set_id -> ad_group_id
	ad_set_name                    											as ad_group_name, -- ad_set_name -> ad_group_name
	
	impressions             												as impressions,
	clicks                 													as clicks,
	spend                          					          				as cost, -- spend -> cost
	conversions                												as conversions,
	
	-- Row level ratios
	clicks / NULLIF(impressions, 0)		                                  	as ctr_row,
	conversions / NULLIF(clicks, 0)		                                  	as cvr_row,
	spend / NULLIF(clicks, 0)	     	                                    as cpc_row,
	spend / NULLIF(conversions, 0)                                          as cpa_row,
	
	-- Support platform-dependent metrics, null if platform does not contain the metric
	video_views                												as video_views,
	reach                           										as reach,
	frequency                      											as frequency,
	
	NULL			                										as conversion_value,
	NULL				                   									as quality_score,
	NULL							                						as search_impression_share,
	
	NULL								                   					as video_watch_25,
	NULL									                      			as video_watch_50,
	NULL									                  				as video_watch_75,
	NULL												                   	as video_watch_100,
	NULL												                   	as likes,
	NULL												                   	as shares,
	NULL													                as comments

FROM 
FACEBOOK_ADS

UNION ALL

-- Google mapping
SELECT
	-- Core metrics
	date               													as date,
	'Google'															as platform,
	
	campaign_id			                         						as campaign_id,
	campaign_name                  										as campaign_name,
	
	ad_group_id                        									as ad_group_id,
	ad_group_name                      									as ad_group_name,
	
	impressions                											as impressions,
	clicks                 												as clicks,
	cost                          										as cost,
	conversions                											as conversions,
	
	-- Row level ratios
	clicks / NULLIF(impressions, 0)	                                   	as ctr_row,
	conversions / NULLIF(clicks, 0)	                                   	as cvr_row,
	cost / NULLIF(clicks, 0)                                            as cpc_row,
	cost / NULLIF(conversions, 0)                                       as cpa_row,
	
	-- Support platform-dependent metrics, null if platform does not contain the metric	
	NULL                       											as video_views,
	NULL                           										as reach,
	NULL                   												as frequency,
	
	conversion_value                       								as conversion_value,
	quality_score                      									as quality_score,
	search_impression_share                					        	as search_impression_share,
	
	NULL				                       							as video_watch_25,
	NULL					                  							as video_watch_50,
	NULL						                 						as video_watch_75,
	NULL						                     					as video_watch_100,
	NULL							                					as likes,
	NULL								                   				as shares,
	NULL										                 		as comments
	
FROM 
GOOGLE_ADS

UNION ALL

-- TikTok mapping
SELECT 
	-- Core metrics
	date               													as date,
	'TikTok'															as platform,
	
	campaign_id                    										as campaign_id,
	campaign_name                      									as campaign_name,
	
	adgroup_id                 											as ad_group_id,
	adgroup_name                   										as ad_group_name,
	
	impressions                											as impressions,
	clicks                     											as clicks,
	cost                           										as cost,
	conversions                											as conversions,
	
	-- Row level ratios
	clicks / NULLIF(impressions, 0)		                                as ctr_row,
	conversions / NULLIF(clicks, 0)	                                   	as cvr_row,
	cost / NULLIF(clicks, 0) 	                                     	as cpc_row,
	cost / NULLIF(conversions, 0)                                       as cpa_row,
	
	-- Supplemental metrics
	video_views                											as video_views,
	NULL                   												as reach,
	NULL                   												as frequency,
	
	NULL			                									as conversion_value,
	NULL				                   								as quality_score,
	NULL					                  							as search_impression_share,
	
	video_watch_25                     									as video_watch_25,
	video_watch_50                 										as video_watch_50,
	video_watch_75                 										as video_watch_75,
	video_watch_100                										as video_watch_100,
	likes                  												as likes,
	shares                 												as shares,
	comments               												as comments
	
FROM
TIKTOK_ADS;