#!/usr/bin/env python3
# Headless interaction verification for the gallery (playwright).
# Build first: elm make Main.elm --output=elm.js
from playwright.sync_api import sync_playwright
with sync_playwright() as p:
    b = p.chromium.launch(headless=True)
    page = b.new_page(viewport={'width':1200,'height':900})
    page.goto('file:///mnt/pulsechain-sata/Projects/abraxas/elm-web3-ui/examples/gallery/index.html')
    page.wait_for_timeout(400)
    # RemoteCall: fire then STALE answer -> must still be loading (skeleton)
    page.click("text=fire"); page.click("text=stale answer"); page.wait_for_timeout(100)
    still_loading = page.query_selector(".web3-remote--loading") is not None
    print("stale answer dropped (still loading):", still_loading)
    page.click("button:has-text('answer') >> nth=0"); page.wait_for_timeout(100)
    print("real answer landed:", page.query_selector(".web3-remote--ready") is not None)
    # ApprovalFlow happy path
    page.click("text=allowance: plenty"); page.wait_for_timeout(80)
    print("ready state:", page.query_selector(".web3-approval--ready") is not None)
    page.click("text=act >> nth=0") if False else page.click("button:has-text('act') >> nth=0")
    page.wait_for_timeout(80)
    page.click("text=act submitted"); page.click("text=act confirmed"); page.wait_for_timeout(100)
    print("flow completed:", page.query_selector(".web3-approval--done") is not None)
    # Tx lifecycle: 6 advances -> confirmed receipt visible
    for _ in range(6): page.click("button:has-text('advance') >> nth=0")
    page.wait_for_timeout(150)
    print("receipt shown:", page.query_selector(".web3-receipt--success") is not None)
    # AccountPill cycle: 6 clicks returns to connected
    page.screenshot(path='/home/jimothy/.cache/gallery-final.png', full_page=True)
    b.close()
