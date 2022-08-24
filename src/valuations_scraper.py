import re
from dateutil.parser import parse
import pandas as pd
from selenium import webdriver
from webdriver_manager.chrome import ChromeDriverManager
from selenium.webdriver.common.keys import Keys
from selenium.webdriver.common.by import By
import pickle
from tqdm import tqdm
import time

def convert_to_players_df(player_prices_dict):
    price_df = pd.DataFrame()
    
    for pn, val in player_prices_dict.items():
        try:
            dob_raw = player_prices_dict[pn]["dob"].split("Date of birth/Age: ")[1].split("(")[0].strip()
            dob_dt = parse(dob_raw)
            dob = f"{dob_dt.year}-{dob_dt.month}-{dob_dt.day}"
            pos = player_prices_dict[pn]["pos"]
            
            item_counter = 0
            for it in val["prices"]:
                if it:
                    content = it.split("\n")
                    date_val = parse(content[0])
                    num_value = float(".".join(re.findall("\d+", content[1])))
                    mult_fraction_value = content[1].split(".".join(re.findall("\d+", content[1])))[-1].lower()
                    mult_fraction_value = 10**6 if mult_fraction_value=="m" else 10**4
                    price = num_value*mult_fraction_value
                    if date_val.year == 2021:
                        if date_val.month in [3, 4, 5, 6, 7]:
                            if not item_counter:
                                item_counter+=1
                                print("hello")
                                price_df = pd.concat(
                                    [
                                        price_df, 
                                        pd.DataFrame(
                                            {
                                                "player_name": [pn],
                                                "season": [2021],
                                                "market_value_eur": [price],
                                                "dob": [dob],
                                                "position_code": [pos],
                                            }
                                        ) 
                                    ]
                                )
        except:
            print(pn)
            continue
    return price_df

##############
##############


player_names_sb = player_names_sb[-10:]
driver = webdriver.Chrome(ChromeDriverManager().install())
driver.get('https://www.transfermarkt.com/')
action = webdriver.ActionChains(driver)

#after this step you need to click on ACCEPT ALL in browser



player_prices_dict = {}

player_prices_dict["sebastian larsson"]

#pn = player_names_sb[0]
for pn in tqdm(player_names_sb):
    try:
        driver.find_element('xpath', '//*[@id="schnellsuche"]/input[1]').send_keys([pn, Keys.ENTER])
        pos = driver.find_element('xpath', '//*[@id="yw0"]/table/tbody/tr/td[2]').text
        driver.execute_script("window.scrollTo(0, 300)") 
        driver.find_element('xpath', '//*[@id="yw0"]/table/tbody/tr/td[1]/table/tbody/tr[1]/td[2]').click()
        driver.execute_script("window.scrollTo(0, 300)") 
        dob = driver.find_element('xpath', '//*[contains(text(), "Date of birth/Age:")]').text
        
        player_prices_dict[pn] = {
            "dob": dob,
            "pos": pos,
            "prices": []
        }
        
        driver.find_element('xpath', '//*[@id="market-value"]').click()
        time.sleep(1)
        driver.execute_script("window.scrollTo(0, 600)") 
        market_prices = driver.find_elements(By.TAG_NAME, "image")
        for el in market_prices[:10]:
            try:
                action.move_to_element(el).click().perform()
                time.sleep(0.25)
                price_el = driver.find_element('xpath', '//*[@id="highcharts-0"]/div/span')
                player_prices_dict[pn]["prices"].append(price_el.text)
            except:
                print(pn)
                driver.get('https://www.transfermarkt.com/')
                continue
        driver.execute_script("window.scrollTo(0, 0)") 
    except:
        print(pn)
        driver.get('https://www.transfermarkt.com/')
        continue

price_df = convert_to_players_df(player_prices_dict)
price_df.to_csv("players_prices.csv", index=False)