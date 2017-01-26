STOCKMARKET = {}

STOCKMARKET.RequiredJobs = nil -- Which job(s) can use the stock market, set as nil for any job. Argument must either be a string or a table of strings. Example "TEAM_STOCKEXCHANGER".

STOCKMARKET.StockHistoryLength = 50 -- How far back the stocks history goes, higher numbers may lag.

STOCKMARKET.MaxStocksOwned = 30 -- How many stocks in each company you can own at once.

STOCKMARKET.StockPriceMaxGap = 0.6 -- Maximum percentage shift the stock prices can move from its original value, 0.6 means 60% up or down.

STOCKMARKET.StockUpdateDelay = 30 -- How many seconds between stock market updates.

STOCKMARKET.StockStartLower = 400 -- Lower limit of random stock prices.
STOCKMARKET.StockStartUpper = 900 -- Upper limit of random stock prices.

STOCKMARKET.Stocks = {"GOOGL", "AAPL", "AMZN", "MSFT", "INTC", "FB", "ORCL", "IBM", "QCOM", "NVDA", "ABDE", "YHOO", "HPE"} -- List of all stocks used.