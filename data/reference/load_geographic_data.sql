-- ============================================================================
-- Load Geographic Reference Data into Temporary Tables
-- ============================================================================
-- This script creates temporary tables with realistic city/state/country data
-- to be used during data generation
-- ============================================================================

-- Drop temporary tables if they exist
DROP TABLE IF EXISTS temp_us_cities CASCADE;
DROP TABLE IF EXISTS temp_world_cities CASCADE;

-- Create temporary table for US cities
CREATE TEMPORARY TABLE temp_us_cities (
    id SERIAL PRIMARY KEY,
    city VARCHAR(100) NOT NULL,
    state VARCHAR(100) NOT NULL,
    state_code CHAR(2) NOT NULL
);

-- Create temporary table for world cities
CREATE TEMPORARY TABLE temp_world_cities (
    id SERIAL PRIMARY KEY,
    city VARCHAR(100) NOT NULL,
    country VARCHAR(100) NOT NULL,
    country_code CHAR(2) NOT NULL
);

-- Load US cities data
COPY temp_us_cities(city, state, state_code) FROM STDIN WITH (FORMAT CSV, HEADER true);
New York,New York,NY
Los Angeles,California,CA
Chicago,Illinois,IL
Houston,Texas,TX
Phoenix,Arizona,AZ
Philadelphia,Pennsylvania,PA
San Antonio,Texas,TX
San Diego,California,CA
Dallas,Texas,TX
San Jose,California,CA
Austin,Texas,TX
Jacksonville,Florida,FL
Fort Worth,Texas,TX
Columbus,Ohio,OH
Charlotte,North Carolina,NC
San Francisco,California,CA
Indianapolis,Indiana,IN
Seattle,Washington,WA
Denver,Colorado,CO
Boston,Massachusetts,MA
Nashville,Tennessee,TN
Detroit,Michigan,MI
Portland,Oregon,OR
Las Vegas,Nevada,NV
Memphis,Tennessee,TN
Louisville,Kentucky,KY
Baltimore,Maryland,MD
Milwaukee,Wisconsin,WI
Albuquerque,New Mexico,NM
Tucson,Arizona,AZ
Fresno,California,CA
Sacramento,California,CA
Kansas City,Missouri,MO
Mesa,Arizona,AZ
Atlanta,Georgia,GA
Omaha,Nebraska,NE
Colorado Springs,Colorado,CO
Raleigh,North Carolina,NC
Miami,Florida,FL
Long Beach,California,CA
Virginia Beach,Virginia,VA
Oakland,California,CA
Minneapolis,Minnesota,MN
Tampa,Florida,FL
Tulsa,Oklahoma,OK
Arlington,Texas,TX
New Orleans,Louisiana,LA
Wichita,Kansas,KS
Cleveland,Ohio,OH
Bakersfield,California,CA
Aurora,Colorado,CO
Anaheim,California,CA
Honolulu,Hawaii,HI
Santa Ana,California,CA
Riverside,California,CA
Corpus Christi,Texas,TX
Lexington,Kentucky,KY
Stockton,California,CA
Henderson,Nevada,NV
Saint Paul,Minnesota,MN
St. Louis,Missouri,MO
Cincinnati,Ohio,OH
Pittsburgh,Pennsylvania,PA
Greensboro,North Carolina,NC
Anchorage,Alaska,AK
Plano,Texas,TX
Lincoln,Nebraska,NE
Orlando,Florida,FL
Irvine,California,CA
Newark,New Jersey,NJ
Durham,North Carolina,NC
Chula Vista,California,CA
Toledo,Ohio,OH
Fort Wayne,Indiana,IN
St. Petersburg,Florida,FL
Laredo,Texas,TX
Jersey City,New Jersey,NJ
Chandler,Arizona,AZ
Madison,Wisconsin,WI
Lubbock,Texas,TX
Scottsdale,Arizona,AZ
Reno,Nevada,NV
Buffalo,New York,NY
Gilbert,Arizona,AZ
Glendale,Arizona,AZ
North Las Vegas,Nevada,NV
Winston-Salem,North Carolina,NC
Chesapeake,Virginia,VA
Norfolk,Virginia,VA
Fremont,California,CA
Garland,Texas,TX
Irving,Texas,TX
Hialeah,Florida,FL
Richmond,Virginia,VA
Boise,Idaho,ID
Spokane,Washington,WA
Baton Rouge,Louisiana,LA
\.

-- Load world cities data
COPY temp_world_cities(city, country, country_code) FROM STDIN WITH (FORMAT CSV, HEADER true);
Toronto,Canada,CA
Vancouver,Canada,CA
Montreal,Canada,CA
Calgary,Canada,CA
Ottawa,Canada,CA
London,United Kingdom,GB
Manchester,United Kingdom,GB
Birmingham,United Kingdom,GB
Edinburgh,United Kingdom,GB
Glasgow,United Kingdom,GB
Berlin,Germany,DE
Munich,Germany,DE
Hamburg,Germany,DE
Frankfurt,Germany,DE
Cologne,Germany,DE
Paris,France,FR
Lyon,France,FR
Marseille,France,FR
Toulouse,France,FR
Nice,France,FR
Rome,Italy,IT
Milan,Italy,IT
Naples,Italy,IT
Turin,Italy,IT
Florence,Italy,IT
Madrid,Spain,ES
Barcelona,Spain,ES
Valencia,Spain,ES
Seville,Spain,ES
Bilbao,Spain,ES
Sydney,Australia,AU
Melbourne,Australia,AU
Brisbane,Australia,AU
Perth,Australia,AU
Adelaide,Australia,AU
Tokyo,Japan,JP
Osaka,Japan,JP
Kyoto,Japan,JP
Yokohama,Japan,JP
Nagoya,Japan,JP
Beijing,China,CN
Shanghai,China,CN
Guangzhou,China,CN
Shenzhen,China,CN
Chengdu,China,CN
Mumbai,India,IN
Delhi,India,IN
Bangalore,India,IN
Hyderabad,India,IN
Chennai,India,IN
Sao Paulo,Brazil,BR
Rio de Janeiro,Brazil,BR
Brasilia,Brazil,BR
Salvador,Brazil,BR
Fortaleza,Brazil,BR
Mexico City,Mexico,MX
Guadalajara,Mexico,MX
Monterrey,Mexico,MX
Puebla,Mexico,MX
Tijuana,Mexico,MX
Moscow,Russia,RU
Saint Petersburg,Russia,RU
Novosibirsk,Russia,RU
Yekaterinburg,Russia,RU
Kazan,Russia,RU
Lagos,Nigeria,NG
Kano,Nigeria,NG
Ibadan,Nigeria,NG
Abuja,Nigeria,NG
Port Harcourt,Nigeria,NG
Karachi,Pakistan,PK
Lahore,Pakistan,PK
Islamabad,Pakistan,PK
Rawalpindi,Pakistan,PK
Faisalabad,Pakistan,PK
Tehran,Iran,IR
Mashhad,Iran,IR
Isfahan,Iran,IR
Karaj,Iran,IR
Tabriz,Iran,IR
Pyongyang,North Korea,KP
Hamhung,North Korea,KP
Chongjin,North Korea,KP
Nampo,North Korea,KP
Wonsan,North Korea,KP
Damascus,Syria,SY
Aleppo,Syria,SY
Homs,Syria,SY
Latakia,Syria,SY
Hama,Syria,SY
Caracas,Venezuela,VE
Maracaibo,Venezuela,VE
Valencia,Venezuela,VE
Barquisimeto,Venezuela,VE
Maracay,Venezuela,VE
Havana,Cuba,CU
Santiago de Cuba,Cuba,CU
Camaguey,Cuba,CU
Holguin,Cuba,CU
Santa Clara,Cuba,CU
Yangon,Myanmar,MM
Mandalay,Myanmar,MM
Naypyidaw,Myanmar,MM
Mawlamyine,Myanmar,MM
Bago,Myanmar,MM
Kabul,Afghanistan,AF
Kandahar,Afghanistan,AF
Herat,Afghanistan,AF
Mazar-i-Sharif,Afghanistan,AF
Jalalabad,Afghanistan,AF
Baghdad,Iraq,IQ
Basra,Iraq,IQ
Mosul,Iraq,IQ
Erbil,Iraq,IQ
Kirkuk,Iraq,IQ
Tripoli,Libya,LY
Benghazi,Libya,LY
Misrata,Libya,LY
Zawiya,Libya,LY
Bayda,Libya,LY
Khartoum,Sudan,SD
Omdurman,Sudan,SD
Port Sudan,Sudan,SD
Kassala,Sudan,SD
Nyala,Sudan,SD
Mogadishu,Somalia,SO
Hargeisa,Somalia,SO
Bosaso,Somalia,SO
Kismayo,Somalia,SO
Merca,Somalia,SO
Sanaa,Yemen,YE
Aden,Yemen,YE
Taiz,Yemen,YE
Hodeidah,Yemen,YE
Ibb,Yemen,YE
Harare,Zimbabwe,ZW
Bulawayo,Zimbabwe,ZW
Chitungwiza,Zimbabwe,ZW
Mutare,Zimbabwe,ZW
Gweru,Zimbabwe,ZW
Amsterdam,Netherlands,NL
Rotterdam,Netherlands,NL
The Hague,Netherlands,NL
Utrecht,Netherlands,NL
Eindhoven,Netherlands,NL
Stockholm,Sweden,SE
Gothenburg,Sweden,SE
Malmo,Sweden,SE
Uppsala,Sweden,SE
Vasteras,Sweden,SE
Oslo,Norway,NO
Bergen,Norway,NO
Trondheim,Norway,NO
Stavanger,Norway,NO
Drammen,Norway,NO
Copenhagen,Denmark,DK
Aarhus,Denmark,DK
Odense,Denmark,DK
Aalborg,Denmark,DK
Esbjerg,Denmark,DK
Helsinki,Finland,FI
Espoo,Finland,FI
Tampere,Finland,FI
Vantaa,Finland,FI
Oulu,Finland,FI
Zurich,Switzerland,CH
Geneva,Switzerland,CH
Basel,Switzerland,CH
Lausanne,Switzerland,CH
Bern,Switzerland,CH
Singapore,Singapore,SG
Hong Kong,Hong Kong,HK
Kowloon,Hong Kong,HK
Seoul,South Korea,KR
Busan,South Korea,KR
Incheon,South Korea,KR
Daegu,South Korea,KR
Daejeon,South Korea,KR
Taipei,Taiwan,TW
Kaohsiung,Taiwan,TW
Taichung,Taiwan,TW
Tainan,Taiwan,TW
Hsinchu,Taiwan,TW
Auckland,New Zealand,NZ
Wellington,New Zealand,NZ
Christchurch,New Zealand,NZ
Hamilton,New Zealand,NZ
Tauranga,New Zealand,NZ
\.

-- Create indexes for faster lookups
CREATE INDEX idx_temp_us_cities_id ON temp_us_cities(id);
CREATE INDEX idx_temp_world_cities_id ON temp_world_cities(id);
CREATE INDEX idx_temp_world_cities_country_code ON temp_world_cities(country_code);

-- Show counts
SELECT 'US Cities loaded: ' || COUNT(*) FROM temp_us_cities;
SELECT 'World Cities loaded: ' || COUNT(*) FROM temp_world_cities;

