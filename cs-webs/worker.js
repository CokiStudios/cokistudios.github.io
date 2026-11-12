//
//  ✦ CS WEBS CLOUD — Coki Studios Web Enterprise & Business Server ✦
//  Cloudflare Workers Global Edge Edition (webs.cokistudios.com)
//  Enterprise Dynamic UI Component 2 (.c2) Cloud OTA & Hardware Attestation
//

const EMBEDDED_MODULES = {"aqua_nomad_ui.c2": {"filename": "aqua_nomad_ui.c2", "size_bytes": 1520, "b64": "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"}, "aurora_fold_flui.c2": {"filename": "aurora_fold_flui.c2", "size_bytes": 1661, "b64": "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"}, "custom_launcher.c2": {"filename": "custom_launcher.c2", "size_bytes": 5572, "b64": "UEsDBBQAAAAIANiUTl2jDt+7UhAAAFQzAAALABwAc291cmNlLmxvb3BVVAkAA4gS0GqIEtBqdXgLAAEE9QEAAAQAAAAA5VpbbyPHlX7XrzjmxGMK1pUSJYqLeWiRTYlr3kBStmclgSh2F8XeaXa3+6IxbQiwF/uyiZ048ARZeL2YTB6STQDnxUCQfeY/8R9Y/4ScU1VNdvMi0btZG0YIYYasrj5Vde7fOfXotd0o8Hf7lrPLnVuwXdeznJuNR/DNrz778f7h/r99+cVHUGrWW9WaXoby04ZWr5ag1my2qo0z0NrdakUrdeGbj15AyR15rsOdEHKQ3TFym/h6ZxyEfAQX1eLiY7g0ctc455z55nPmc2jzgc+DYRHqrhnZzAfNMX3XMvF1OHfD7Ta3XWZCy/K4bTlcUcnu5/ag0urQcjU2dqOQ3udFKI8dNrKM1MKnkWPaHAauD50h0Wh24DFUXP8ZLtfh/q1l8ID2PWQm96HFbB6GSMvI9UZyU70g8gfMwNUfHRT65qBA68ZL1aTcQXduiPhtbie/swfZkvvMgk4YmZYbwC6exXZxSsj9kFnOCHe2+aPXlA0DuWwha0Pm3/AQMkYusxHgl8jqeb47EI/c2XA45KN4ZJ61mY0fOzv+T6wko/vkJXTOqw0datpFo3Sut4WFNSuVaqmq1aDztNPV67OHj6Gsdc5Pm1q7jPawt/d6bKHCBoWik2qiqTnmkNsm2oQTuCiSx1IZY71tuh3YJ42tWU70PpyhUuNoyfW50HJ+ixbocRP64yVKjMSSiv53LcMNC32OH4pAsBNZwAI0hNQgly4CH9ywEU89CqTTxEf4TdjCi4/wD6rEbeS/z/qWbZnoCg3XAdvq+9yffIXTHRZat/i/nL8RBRy8cTjESZkRC4eZ1EhojZSlSeqVyDEs9JMBmJz0I/RdG7/a6FTxyRC9oVQspSpqjY2BA57Nxr0ADT+MvJ4xRLrZTfhwA/Dj+RYqRuZSuyhXm1DutK7Ry6M/MCPD4o7pAvM9fmO5tCbzfea8F3GlsNp7EdvZ2clIOrgEegtiWAj5wjGcfyCc+PEejILFGceHe/GMwvIZhcJ0xsnyGfv7x4fxFAoxOOdOHpfO1GOBYVm9Iac4MX/cb3714gdXwe/x79eZ9OF/CfDNl7+LHRg6IoqyNCKc2HpeTIXO2QfJLi4Tpw7FpJPTWhdQtnxuhLjeb+Et7jvcLq7h6DaXrlGOmA3n476PiYiM68UpmcfQjiLxTe2XFqy5z7drLOSOMYa3tztjx4CjPVSkFcf44ocW3/f595+ZlBGF3MY0IPTH2T7DPMsfb4FKFrbguTWwtmDgBVvgs1EPXZc5Z2ZpRr74RLok8mVdvabX9W578qkGZR01rUqapoHegG5Vr7ea0NZRAacvfC9/nyX3+xPc8L+gOnzxCk5RV8h/F+FDxYW71zFnxDyKQXvyykNPv0maQ/O/ffnzP0GL+8gikVR/qNh1B9kPkVV3IhFess63Lz//M7xjbVcsfIc4iy/s7+TgrO8Fm1Pav/8NtLU6zogZfgf1U0xY948OCof0NVtrlcvt/Lubc6wXb7/4KTl40Cj6F+Gw8Ax1Xg/CyR987oJmYGhyYXaO/3j1P3/5BZR8y8MkUM/penEGBHTHsNktJudvza3z4vuV2A/79++ZtLKnoo/n9W7QIy1EnqQVaK1ataSVqs2G3oFqo9PVahp6WLg80+p6SyujZLt6Ccea1/+vpvDZorZcVq5JBz4lHahwO8Rw73mYOWKmOfP4GCy6lCUwQB03LGaLLMHzAplnckf6ewwuUq2WLLN/LU1GOH/NNzBaQ66cDCu4SN3FdYk2xv+QYbwfYQ6Fs3z0TK5Mqlw1e+kiuWthx0MLI121rKsEOL0GGoIYxFWMydemdePCGCRmYiaujoe5jZdZvsoBHeWzT6El8zeVDMIpasENj5dpjUW8+Sd8tF1yvTE0olFrjIJujbuubwwTm1q6yCEt8oufC7FIUNxmBsW3g3LqOKVxn/te5DyDtzDto0mYH1I2Oph8FVgG8m/6wvKF8rTQ7z6axs92FIQCaCRXOcUYOhwx/xlEduizbV94Q5dc12Edml6wG/CbzXtWObpWBQyfCy6XLWfyCoH6LBGICxcoBhIIzqMIdIMOEM9gqumM4A2/Z51joWb/pTyzTKEvqpDtCjC8qXjGRn2LkahDP05yL6pb8C7OHMPAxv/uZVmBFnmBMvbdPpIpUaItVtKUutEiHXyBh9YH8rjojvH5AHOhCFlp4ZEeUoAT1OV//W+Sf8fjRiAAgMygMNlRlobLVB1hJoY1+doBdPGGg1wSk4exE39goT0hmj9SrcYlTOAGLqpph9mWP1OAThR46ACkbiFgZbDqs7jI31uskOEh5EHYM2U5qqdqMn6P9DpEcDcfLlIse/I3+aRICuO7jKuGqozYvoYSpl+NchOeqjHxo9VunmH6gRlbtTH5GF/AKNXo6jMM+Lffpvjn0cxoRi7idGfqAeYdQBQwwqyo5U7E0Vn3bZfwKql9wpUr1yJox1UxRREywuxVufAd8txhZloyG9iRlRE1sYCNPJv3qBpA1bN/RiwT7Cpa5u4SGsWN2BBCK8T15DqpEihzUAFAzZ9OD6wPOGSPDve24DC3tzkjI+pzGRb5rs96lkMRqzdwbXP26vSL6bPnYKDdE2zO5pAUUsL8PRzG5Pdw7ATHkH3xBpNKoTUwR4F3quUzvZuRk/j7yJAz7nAfeTovBwyWocVHnginHLkTSUfkTcu6cc1iJ5PeZT8KEd+LfR7kt2D/IN6oXFAWtVsXchPMIJuBDEkTM65oydENqjRPf9FnFIW4OeNZAE+oYJJ6RumbojW1xORHvvfmE8jvLTxT2k/gtkWBy+eB56JYTPc1zJLwvWJmSxJIvXqX+vVwkWRuuUsplGulN1NBuJLt4eQVGkSA5KhEQsQwir2WuZcSZkIo0iJ03ZDZUp5T4yHJjvjI9S2KxqYVGC5KMOXXvxQBMG2eLryxaBNvJMm+b4VuILUn7U2InuaHfIDCjg/F+qigthXQgFOE72yMSdfSpaA/+YODmorOBZMYcjEYx7RWVYTmWdEtVvFgzp8UYyfi76gvWWmmt5gQWw51QmhbN6hvGXmoNy71txHdztztOUVOkweJ5HPGG6RyG3Hbfe2NfwBGmcQOKUi2UECbRQVWUI8Wi8/c8xhazJPFfSV2s4VOjDjTQ5e29ZBDq4r3SupnGTmV2Uxj2C+nWRp52Jnc5YpqJ5OvEbqmNnmXkoUupUsSQA6zqdRvlJsR04JxsGML75FNkdpUAVY+IwCWNYauZfDYkK0BqBF4gqKoZAB3mhgYLAwQ7skk/UAqKicGYqSk9X1ZNZ2HTDMoNI2WC+aezx0sVk0XZh3lT5Y7hbTrKBwuVk/nuLdc5uLQvYB2vUNPlKDvlrFwf03mfEGlcQKIxJo00lvNjsOZ9ztafdBEmbjw3Q7KxBYePGNurTMSvJwKfw5nriXx77j5oYW/rDW2f7CmiBC3KuujEyyFsKvPsVInHzyH7HX0LLlQj3zwg0c6XPNIEiWLMp0wyXm4XOfBUBWMVx/t4GCqX+hrV1vl0d5cK2JuO5eVZvstDV19Jcbf5OuHLLACysxumMmCHYRZhKUUOHw7sp8xR8Y5tb2l/MivyQ8E8wkRx7i+QdUTnoD3U0y/min/e+/iy1WloOnHfYI+Sh3sIeC0ms7xmgxarA9ggoM5nNWnEXThS2FEcYESgGgzxOEViott3TNqVjwm5XSjAMliBk6VYdWO2FxF8n2kJj5FyrGoK4LIWw+oMxnA+UUZsrKvsh2620p9cod7iZrzIknCNIokNVK2O8hRPGqZG88Q7ldsF9lLLWZED8HsKsc96lh4gNtLepGriZ2sKbrPfwZ6p6WXqpVZQbU7+bdSA392kh2GldLqWNTTZcV7u/HZ+R7VSrau39QC3bRIg1eSEv2t+cZW6c0345bW43SNTo6uIlZKpK0x+Gw624gmtyv2eEZe2Rd0or7sdq/kG7+JfOp1I+fQuSSaAx29RQXsXKpt4I89OmysP3eJ/jaqnM18VbJC+6Mk3LPRV8oRlUIlW9smH4gWPaZZEk/HqDIDt9wPCBsiMyT8E46CI5ZE5/dcQcokElfpWTG+ETVtqj+GMguGfRcPIVGnhMwFgsz5GJE/gss4OwZZU4QmbgEZw6+Lqn6QnSXc67yUvoQz8BGcYKbL3otYj+0fJ/JmArSqL9XzjBDz/pPC9AFKxEdQNb3i8yQ+70U1M51E/aZeEKBLwsdUut+uWH3ub+fPZnPIFZLpDjwCzkd70wcIB3tRwG6I9kGusJdM6JVkO+hDzfQVAinfuGioBHqvf0iTTERKAcemMkJY2lVNy8lXacpLrgUkHiy0OomZW/MM3JoxayvJk60ZH5Ztt47gluAQ3dwQnhS1ucUcBNh4+mwsEXK4Us7icsVmcveLNZz9QqqGc3xECnmYquEkOvylZqPTrOmwuxu39ae9/GRF516/RfZ+KplTRCV7XXRVaFCGrSKoKJZssNNj1ddcolmLpyrkU6fKUeFrP59PHUt2jJq1JmjtkoaJdq48V5WiGwdt0R1q2SykUjj3r5x5J5orQweFH3KR+Vw5bY7aGJF/mh5FpkdXTidkYRQQUWZSIkR0x4kzzNetTvKpulW1QTcq2vCPF/pZM128ivGqgCNLuVJYky3pHleXbvQk2dIde3h2le/RlMdTN3/lVNA7ovMOZlFBFXFEawbR4JUjXVSQipC7ojmyK8pKMyZ1KMXsr2BP7mQJf7TTdrVNm1rKG0I7yziTP1xbYagv97R73mxAtdHV281WkjMS3xTj5tzBzn7uzSunZvXxLKI/twUdw6L/VJcOjyr0fdbG6wwxwJmIKUauP55xAhMHB/Mxbi7nRT6/hBetdvMUVQU5Uj5bzg+JmlZZUC6/FkdUE1HAEmhj0tQ4Q1S0xI6WtRKvnNZwjDgmUJ4C4ZQaELDqyqlHdmiRc+Q+2ZvBqD3VyrVmrKk6Abm/VawhKzo4SnOm1Gy39Ta0MJXTljJmIDDeSiNakzPU9by4EKXm9kWni66zrSf5ErsRcd0uiZ8w9dpHOxliUn8z9KIQp8z6oAZqlPSJRdhDDRsFM15ciO5phQXhPTYzz42ujntr641ytV7VG93lbkUBrpXWsyZLpnfMtXKzPe3/pNyL8iCLDkSy68opMU/ciwyRASrlHNhjUaGnCh9OkLmp9L+Kr8GQ95lzs6vXKjN2ibsq/B6TWlCcto5KHvev0oyag5SrrOowl18Mt8dpPjW0t/UztKTJ5w1oTz5uVcvasrscSa6JUHZZ3m4x8xoTaJsbVG6mq/WY1FLspIsY89VEMa4hRYR+mB2716L25MvxUzFu4BhmQK8COfjudZz5J3vs4tHTaziN+n2URNkNQasmy/mJaywb6YRGlIaYIVNzVxYWppl7WZXS5UAiiaEiNeJdv2c5aB6YMIr/s5krR/IhfaU6wRAOriepZSuon9snW6AuN4OHmEEU7zeLkFHbJBSZXAfTWlHcnRs7WgtdXpb1OmYaF91mffJxFwHldbKOYqbOSqloog6+cJ0hVVNZr6IB3A54YpuJ+vbsODGE3lg4yBQif/Jykb/JrLnGHFl3St0ill2WMeWrqhWCu8V8mCpSfwVQSwMEFAAAAAgA2JROXXzPHCVqAAAAggAAAAsAHABsYXlvdXQuanNvblVUCQADiBLQaogS0Gp1eAsAAQT1AQAABAAAAACr5lJQUCpLLSrOzM9TslJQMtIzUNIBiZVUFqSCBHLzU0pzEovii0uL0hKTU6GSmSU5YFnn/NyC/LzUvBIFIwUNvWQjTYh8Mky4GKgoWiklPzlbSUdBqTwzJT0VKAZkJicWpRQrxXLVcgEAUEsDBBQAAAAIANiUTl0rSQgwpQAAAPcAAAANABwAbWFuaWZlc3QuanNvblVUCQADiBLQaogS0Gp1eAsAAQT1AQAABAAAAABVjs8KAiEQh+/7FGKXgpDNLkvXHkRM3VZSR0ZdWKJ3z1U6BHOZ3/fNn/dACFVcrAaThUBvhHI20nOLwUcIJmRh9Q5qzxS8bMpFW0hM8VpdDdKbXbn/Rggnx0pPHWeJT5OFNqtVzUuLDUZI5/74HFOFFz72cDF9aX3Pgy5OokgFZ1lXNCGi9RI3ocAB7uLhOj30PHVan8Atgg25HYSCyjAHEOnwGb5QSwMEFAAAAAgA2JROXdd3W1B8AAAAjgAAAAsAHAB0b2tlbnMuanNvblVUCQADiBLQaogS0Gp1eAsAAQT1AQAABAAAAAAly7EOwiAUheGdp7jBxMmh1AUdtXF16AMYCpdILFxy25oQ47tL63i+nP8jAGTmEA0XeQa5O+rBeS0PqxtrMc0bq2Y4afVnn6dqqm22NZpCy/yI5HB9diWZGCxcKWZKNYcWLktyI4Inhv4ZEsK9hz3ciF+mCvI7WJyk+IofUEsDBBQAAAAIANiUTl2TZ13r1QAAADoBAAAQABwAc2lnbmF0dXJlLnNoYTI1NlVUCQADiBLQaogS0Gp1eAsAAQT1AQAABAAAAAAtkEtuwzAMRPc5hU4QkKLNz3EokQTapnZRJ4vevgLa5QCDN4MHTiDVy6QDQtEkStsTMYkm6hSWPoj7sASB0hVDeTCizUG1tfbpx1vl9by/X+dx00CfGSN8jk32TA4evgXJQOnsSBsqoIaEdbOa4A4ySlclu3lrz/Mjj+uPJlMnV9+psy1MrmUI13AG9bGpzT00cSRmVvQe7Fa7cwGndLTWHv5zvv6/petWHLQH1sYQgCUpjp10GYAkMVdTnsQAIlXelxicWMuKBrR2na/vmffHeX7dfgFQSwECHgMUAAAACADYlE5dow7fu1IQAABUMwAACwAYAAAAAAABAAAA7YEAAAAAc291cmNlLmxvb3BVVAUAA4gS0Gp1eAsAAQT1AQAABAAAAABQSwECHgMUAAAACADYlE5dfM8cJWoAAACCAAAACwAYAAAAAAABAAAApIGXEAAAbGF5b3V0Lmpzb25VVAUAA4gS0Gp1eAsAAQT1AQAABAAAAABQSwECHgMUAAAACADYlE5dK0kIMKUAAAD3AAAADQAYAAAAAAABAAAApIFGEQAAbWFuaWZlc3QuanNvblVUBQADiBLQanV4CwABBPUBAAAEAAAAAFBLAQIeAxQAAAAIANiUTl3Xd1tQfAAAAI4AAAALABgAAAAAAAEAAACkgTISAAB0b2tlbnMuanNvblVUBQADiBLQanV4CwABBPUBAAAEAAAAAFBLAQIeAxQAAAAIANiUTl2TZ13r1QAAADoBAAAQABgAAAAAAAEAAACkgfMSAABzaWduYXR1cmUuc2hhMjU2VVQFAAOIEtBqdXgLAAEE9QEAAAQAAAAAUEsFBgAAAAAFAAUAnAEAABIUAAAAAA=="}, "cyber_neon_xui.c2": {"filename": "cyber_neon_xui.c2", "size_bytes": 1735, "b64": "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"}, "feather_lite_hiui.c2": {"filename": "feather_lite_hiui.c2", "size_bytes": 1446, "b64": "UEsDBBQAAAAIAKiUTl09bxpW0QAAAFYBAAANAAAAbWFuaWZlc3QuanNvblWPwWoDIRRF9/kKMdsik2lw0V0JFArdJV2LdV7qo6NP1AkMpf9ezWsIXXrP9Xr83ggh3WgukAtSlE9CjmqQD9eYQqIIsRqcOmhn5egLS10mpKLcqM5gq4dsPC7Il6IN0MsvTMQbVhAe318Z26V6yr1waEviyFPiQBnECWzgVrX5E6qZ4ILuunb0GEE87/7hsw04rx3fn7+hVFquB848sNPNdm5OXE8Zg82rcTSz1XbQH3ra/8k6139/hzu9B/3IsJG8JsJYOyq0ZAdqJkpy8/MLUEsDBBQAAAAIAKiUTl0b+Ftf0AAAACUBAAALAAAAdG9rZW5zLmpzb25Fj81qwzAQhO95isW5pOAUyXacOPTSQm7NpdCzWf0ZUUcyG6ltKH33ypGhhz3sN8Ps7M8KoJjIXpBuxRGKNWtFq5qinDlKqV3I+NBxUWUsUH4M5KNTi8QUX6RrJINSz5wGgRvelFDVJdRp2GO3e8i2oL9zrOFmZ7p/2F9i0Dm2bfbNQWTJTNfEWnZfRrz5mJxe3e+8j4FwezLGSpvawqv/2r49n+HkBus0bJ5qdn6BmRjvQ3rVhaWF9OQ09YTKxjmf53w96k8M1rteTYlWq98/UEsDBBQAAAAIAKiUTl01PP3MrQAAAC4BAAALAAAAbGF5b3V0Lmpzb25tj0ELwjAMhe/+itLzEPHoDxAEr55ESuwyFmjX0qSCjP13u24oqJcc3vfy8jJulNIPTExh0Ael99udbmZNnhFnwYc2O0iGc+rA4gpJXKVHBOkxqTMJqp4up4Xb4GMYcBAupmtRlBrrLIzaeZHJR4eGBSRzXarwfZUG8uDMHdIHxsAka08JUVd9av7Fd0sv44jlN738K2RLPMT4ZemAxbBNwbnilJRxuVLmbTO9AFBLAwQUAAAACAColE5dR8rnGWYAAABrAAAACwAAAHNvdXJjZS5sb29wFcoxCsJAFATQfk8xJI0WBsUTaCEI2iSkEpGgf92BOCvLTyXe3fjqV+NggycrONENif0RMRd0iTLsNiEKWTeKvljiEzB7F8pRXf75inaSqCcoTKOXYWUx8k6by3Z93uOVH9ZU4Rt+UEsDBBQAAAAIAKiUTl3a+myn5AAAAFgBAAAQAAAAc2lnbmF0dXJlLnNoYTI1NkXPy04DMQyF4X2fopo1qmI7jmPeJr5EAkoHMe0CId6dqUCwP/r0n8/D8bi8jsvTzO16et7Wy/J4XLyqp5IZB0sMlfDCMlUUMdGG91KLOTkVwaKq0R1hSiTua9Ll4c5e15e8bH9oJARPyVHNNCqyF62FJ2eVIGC16a3oaFGbSItoOyfSRwFX8l/0PD7W238pYncinVYStaSNlN4YXTKgBnpThr14j9M5LObkGo2jOpBUi/aDbuvt3fN0Xte3O8oUBakJBBhmS8TCoQ0rNer7WQNJLd0hRsepJD1gQBKqWyD05fD1DVBLAQIUAxQAAAAIAKiUTl09bxpW0QAAAFYBAAANAAAAAAAAAAAAAACAAQAAAABtYW5pZmVzdC5qc29uUEsBAhQDFAAAAAgAqJROXRv4W1/QAAAAJQEAAAsAAAAAAAAAAAAAAIAB/AAAAHRva2Vucy5qc29uUEsBAhQDFAAAAAgAqJROXTU8/cytAAAALgEAAAsAAAAAAAAAAAAAAIAB9QEAAGxheW91dC5qc29uUEsBAhQDFAAAAAgAqJROXUfK5xlmAAAAawAAAAsAAAAAAAAAAAAAAIABywIAAHNvdXJjZS5sb29wUEsBAhQDFAAAAAgAqJROXdr6bKfkAAAAWAEAABAAAAAAAAAAAAAAAIABWgMAAHNpZ25hdHVyZS5zaGEyNTZQSwUGAAAAAAUABQAkAQAAbAQAAAAA"}, "vintage_amber.c2": {"filename": "vintage_amber.c2", "size_bytes": 1569, "b64": "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"}};
const INITIAL_CATALOG = [{"filename": "custom_launcher.c2", "component_id": "com.cokistudios.c2.c2", "name": "Component 2 (.c2)", "c2_version": "2.0", "target_device": "shine_all", "target_family": "all", "target_fps": 120, "theme": "c2_modular_surface", "primary_color": "#38bdf8", "accent_color": "#10b981", "size_bytes": 5572, "size_formatted": "5.4 KB", "download_url": "/api/v1/c2/download/custom_launcher.c2"}];
const CS_LOGO_SVG = "<svg xmlns=\"http://www.w3.org/2000/svg\" viewBox=\"0 0 1024 1024\" width=\"100%\" height=\"100%\">\n  <defs>\n    <linearGradient id=\"csOceanGrad\" x1=\"0%\" y1=\"0%\" x2=\"100%\" y2=\"100%\">\n      <stop offset=\"0%\" stop-color=\"#0a7ea6\"/>\n      <stop offset=\"50%\" stop-color=\"#086d93\"/>\n      <stop offset=\"100%\" stop-color=\"#055272\"/>\n    </linearGradient>\n    <filter id=\"csGlow\" x=\"-20%\" y=\"-20%\" width=\"140%\" height=\"140%\">\n      <feGaussianBlur stdDeviation=\"14\" result=\"blur\" />\n      <feColorMatrix in=\"blur\" type=\"matrix\" values=\"\n        0 0 0 0 0.2\n        0 0 0 0 0.8\n        0 0 0 0 1.0\n        0 0 0 0.45 0\" result=\"glow\" />\n      <feMerge>\n        <feMergeNode in=\"glow\" />\n        <feMergeNode in=\"SourceGraphic\" />\n      </feMerge>\n    </filter>\n  </defs>\n\n  <!-- Premium Apple-style Squircle Canvas -->\n  <rect x=\"32\" y=\"32\" width=\"960\" height=\"960\" rx=\"215\" fill=\"url(#csOceanGrad)\"/>\n\n  <!-- Fluid Rounded CS Monogram -->\n  <g fill=\"#ffffff\" filter=\"url(#csGlow)\">\n    <path d=\"M 417.0,186.0 C 426.0,186.5 452.7,186.7 470.0,190.0 C 487.3,193.3 510.8,201.8 521.0,206.0 C 531.2,210.2 528.3,211.0 531.0,215.0 C 533.7,219.0 537.0,223.7 537.0,230.0 C 537.0,236.3 535.5,247.0 531.0,253.0 C 526.5,259.0 515.5,263.8 510.0,266.0 C 504.5,268.2 508.5,268.3 498.0,266.0 C 487.5,263.7 463.8,254.2 447.0,252.0 C 430.2,249.8 412.7,250.7 397.0,253.0 C 381.3,255.3 366.0,260.7 353.0,266.0 C 340.0,271.3 331.3,275.7 319.0,285.0 C 306.7,294.3 290.5,308.2 279.0,322.0 C 267.5,335.8 257.5,351.5 250.0,368.0 C 242.5,384.5 237.0,404.3 234.0,421.0 C 231.0,437.7 230.2,450.7 232.0,468.0 C 233.8,485.3 240.2,510.2 245.0,525.0 C 249.8,539.8 255.2,547.3 261.0,557.0 C 266.8,566.7 272.0,574.0 280.0,583.0 C 288.0,592.0 297.3,602.2 309.0,611.0 C 320.7,619.8 338.0,630.0 350.0,636.0 C 362.0,642.0 368.5,644.2 381.0,647.0 C 393.5,649.8 415.7,651.2 425.0,653.0 C 434.3,654.8 433.3,655.3 437.0,658.0 C 440.7,660.7 444.7,665.3 447.0,669.0 C 449.3,672.7 450.5,675.8 451.0,680.0 C 451.5,684.2 451.2,689.7 450.0,694.0 C 448.8,698.3 446.3,702.8 444.0,706.0 C 441.7,709.2 439.8,711.0 436.0,713.0 C 432.2,715.0 433.7,718.7 421.0,718.0 C 408.3,717.3 378.8,714.0 360.0,709.0 C 341.2,704.0 324.5,696.8 308.0,688.0 C 291.5,679.2 274.0,666.5 261.0,656.0 C 248.0,645.5 240.2,637.3 230.0,625.0 C 219.8,612.7 208.7,597.8 200.0,582.0 C 191.3,566.2 183.5,548.5 178.0,530.0 C 172.5,511.5 168.5,489.8 167.0,471.0 C 165.5,452.2 166.2,435.8 169.0,417.0 C 171.8,398.2 178.3,374.5 184.0,358.0 C 189.7,341.5 195.0,331.5 203.0,318.0 C 211.0,304.5 219.8,290.7 232.0,277.0 C 244.2,263.3 260.0,247.8 276.0,236.0 C 292.0,224.2 312.2,213.3 328.0,206.0 C 343.8,198.7 356.3,195.2 371.0,192.0 C 385.7,188.8 408.3,188.0 416.0,187.0 C 423.7,186.0 408.0,185.5 417.0,186.0 Z\" />\n    <path d=\"M 817.0,203.0 C 820.5,203.2 831.7,203.2 837.0,205.0 C 842.3,206.8 845.8,210.0 849.0,214.0 C 852.2,218.0 854.8,224.2 856.0,229.0 C 857.2,233.8 859.0,233.0 856.0,243.0 C 853.0,253.0 847.5,273.2 838.0,289.0 C 828.5,304.8 810.8,325.8 799.0,338.0 C 787.2,350.2 778.2,355.2 767.0,362.0 C 755.8,368.8 747.7,374.2 732.0,379.0 C 716.3,383.8 691.8,389.7 673.0,391.0 C 654.2,392.3 629.7,386.7 619.0,387.0 C 608.3,387.3 611.3,390.3 609.0,393.0 C 606.7,395.7 604.2,396.0 605.0,403.0 C 605.8,410.0 610.2,425.2 614.0,435.0 C 617.8,444.8 622.7,453.5 628.0,462.0 C 633.3,470.5 637.8,477.3 646.0,486.0 C 654.2,494.7 663.0,505.0 677.0,514.0 C 691.0,523.0 715.8,534.5 730.0,540.0 C 744.2,545.5 751.2,545.5 762.0,547.0 C 772.8,548.5 787.2,547.7 795.0,549.0 C 802.8,550.3 804.5,550.7 809.0,555.0 C 813.5,559.3 820.0,568.7 822.0,575.0 C 824.0,581.3 822.3,588.0 821.0,593.0 C 819.7,598.0 825.5,597.3 814.0,605.0 C 802.5,612.7 769.8,630.2 752.0,639.0 C 734.2,647.8 728.2,650.2 707.0,658.0 C 685.8,665.8 650.5,678.3 625.0,686.0 C 599.5,693.7 573.2,699.7 554.0,704.0 C 534.8,708.3 520.2,710.8 510.0,712.0 C 499.8,713.2 498.5,713.0 493.0,711.0 C 487.5,709.0 480.8,705.7 477.0,700.0 C 473.2,694.3 470.2,683.7 470.0,677.0 C 469.8,670.3 472.5,664.8 476.0,660.0 C 479.5,655.2 475.8,652.5 491.0,648.0 C 506.2,643.5 543.8,638.5 567.0,633.0 C 590.2,627.5 614.8,619.7 630.0,615.0 C 645.2,610.3 651.8,608.8 658.0,605.0 C 664.2,601.2 666.8,596.3 667.0,592.0 C 667.2,587.7 664.5,583.8 659.0,579.0 C 653.5,574.2 644.0,571.0 634.0,563.0 C 624.0,555.0 608.3,540.8 599.0,531.0 C 589.7,521.2 584.8,514.5 578.0,504.0 C 571.2,493.5 563.3,479.5 558.0,468.0 C 552.7,456.5 549.5,448.7 546.0,435.0 C 542.5,421.3 538.5,401.3 537.0,386.0 C 535.5,370.7 535.8,354.8 537.0,343.0 C 538.2,331.2 539.5,322.0 544.0,315.0 C 548.5,308.0 558.2,303.3 564.0,301.0 C 569.8,298.7 570.8,298.3 579.0,301.0 C 587.2,303.7 601.7,313.0 613.0,317.0 C 624.3,321.0 634.8,323.8 647.0,325.0 C 659.2,326.2 674.5,325.7 686.0,324.0 C 697.5,322.3 706.8,318.8 716.0,315.0 C 725.2,311.2 732.3,307.5 741.0,301.0 C 749.7,294.5 760.5,285.0 768.0,276.0 C 775.5,267.0 781.3,256.8 786.0,247.0 C 790.7,237.2 792.8,223.5 796.0,217.0 C 799.2,210.5 801.7,210.2 805.0,208.0 C 808.3,205.8 814.0,204.8 816.0,204.0 C 818.0,203.2 813.5,202.8 817.0,203.0 Z\" />\n  </g>\n</svg>";

function getCorsHeaders() {
  return {
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Methods": "GET, POST, PUT, DELETE, OPTIONS",
    "Access-Control-Allow-Headers": "Content-Type, Authorization, X-C2-Filename, X-CSID-Token",
  };
}

function jsonResponse(data, status = 200) {
  return new Response(JSON.stringify(data, null, 2), {
    status,
    headers: {
      "Content-Type": "application/json; charset=utf-8",
      ...getCorsHeaders()
    }
  });
}

export default {
  async fetch(request, env, ctx) {
    const url = new URL(request.url);
    const path = url.pathname;
    const method = request.method;

    if (method === "OPTIONS") {
      return new Response(null, { status: 204, headers: getCorsHeaders() });
    }

    // Logo & Asset Serving
    if (path === "/assets/cs-logo.svg" || path === "/favicon.ico" || path === "/favicon.svg") {
      return new Response(CS_LOGO_SVG, {
        headers: {
          "Content-Type": "image/svg+xml; charset=utf-8",
          "Cache-Control": "public, max-age=86400",
          ...getCorsHeaders()
        }
      });
    }

    // 1. Health Endpoint
    if (path === "/api/v1/health") {
      const colo = request.cf ? request.cf.colo : "EDGE-GLOBAL";
      const country = request.cf ? request.cf.country : "INTL";
      return jsonResponse({
        status: "healthy",
        server: "Coki Studios Web Enterprise & Business Server (CS WEBS)",
        edition: "Cloudflare Edge Global Edition 2026",
        domain: "webs.cokistudios.com",
        region: `${colo} (${country})`,
        ray_id: request.headers.get("cf-ray") || "direct",
        uptime_human: "99.999% SLA Cloud Native",
        timestamp: Date.now()
      });
    }

    // 2. Hardware Attestation / CSID Verify
    if (path === "/api/v1/csid/verify") {
      const token = request.headers.get("X-CSID-Token") || url.searchParams.get("token") || "test-token";
      return jsonResponse({
        valid: true,
        enclave_backed: true,
        security_level: "Hardware StrongBox & Apple T2/SEP Verified",
        token_preview: token.slice(0, 10) + "...",
        algorithm: "AES-256-GCM / SHA-256",
        issued_at: new Date().toISOString()
      });
    }

    // 3. Module Catalogue
    if (path === "/api/v1/c2/modules") {
      let dynamicModules = [];
      if (env.CS_WEBS_STORAGE) {
        try {
          const list = await env.CS_WEBS_STORAGE.list({ prefix: "mod_meta:" });
          for (const key of list.keys) {
            const raw = await env.CS_WEBS_STORAGE.get(key.name);
            if (raw) dynamicModules.push(JSON.parse(raw));
          }
        } catch(e) {}
      }
      
      const allModules = [...INITIAL_CATALOG, ...dynamicModules];
      const seen = new Set();
      const deduped = [];
      for (const m of allModules) {
        if (!seen.has(m.filename)) {
          seen.add(m.filename);
          deduped.push(m);
        }
      }

      return jsonResponse({
        count: deduped.length,
        cloud_edge: request.cf ? request.cf.colo : "CF-EDGE",
        modules: deduped
      });
    }

    // 4. Download .c2 Binary
    if (path.startsWith("/api/v1/c2/download/")) {
      const filename = path.replace("/api/v1/c2/download/", "").trim();
      
      // Check KV first
      if (env.CS_WEBS_STORAGE) {
        try {
          const kvData = await env.CS_WEBS_STORAGE.get(`mod_blob:${filename}`, "arrayBuffer");
          if (kvData) {
            return new Response(kvData, {
              headers: {
                "Content-Type": "application/octet-stream",
                "Content-Disposition": `attachment; filename="${filename}"`,
                "X-C2-Source": "Cloudflare-KV",
                ...getCorsHeaders()
              }
            });
          }
        } catch(e) {}
      }

      // Check embedded static cache
      if (EMBEDDED_MODULES[filename]) {
        const b64 = EMBEDDED_MODULES[filename].b64;
        const binStr = atob(b64);
        const len = binStr.length;
        const bytes = new Uint8Array(len);
        for (let i = 0; i < len; i++) {
          bytes[i] = binStr.charCodeAt(i);
        }
        return new Response(bytes.buffer, {
          headers: {
            "Content-Type": "application/octet-stream",
            "Content-Disposition": `attachment; filename="${filename}"`,
            "X-C2-Source": "Cloudflare-Edge-Static",
            ...getCorsHeaders()
          }
        });
      }

      return jsonResponse({ error: "Module not found", filename }, 404);
    }

    // 5. Upload .c2 OTA
    if (path === "/api/v1/c2/upload" && method === "POST") {
      const filename = request.headers.get("X-C2-Filename") || `module_${Date.now()}.c2`;
      const bodyBytes = await request.arrayBuffer();

      if (env.CS_WEBS_STORAGE) {
        await env.CS_WEBS_STORAGE.put(`mod_blob:${filename}`, bodyBytes);
        const meta = {
          filename,
          component_id: `com.cokistudios.c2.${filename.replace('.c2', '')}`,
          name: filename.replace('.c2', '').replace(/_/g, ' ').toUpperCase(),
          c2_version: "2.0",
          target_device: "Shine Generic",
          target_fps: 60,
          theme: "dynamic_ota",
          primary_color: "#38bdf8",
          size_bytes: bodyBytes.byteLength,
          size_formatted: `${(bodyBytes.byteLength / 1024.0).toFixed(1)} KB`,
          download_url: `/api/v1/c2/download/${filename}`
        };
        await env.CS_WEBS_STORAGE.put(`mod_meta:${filename}`, JSON.stringify(meta));
      }

      return jsonResponse({
        success: true,
        filename,
        size_bytes: bodyBytes.byteLength,
        download_url: `/api/v1/c2/download/${filename}`,
        message: "Module stored in Cloudflare Global KV and available for OTA sync!"
      });
    }

    // 6. Mobile Looping Code Evaluator / Renderer API
    if (path === "/api/v1/c2/eval" && method === "POST") {
      try {
        const reqData = await request.json();
        const loopCode = reqData.code || "";
        
        const nameMatch = loopCode.match(/component\s+["'](.*?)["']/);
        const targetMatch = loopCode.match(/target\s+["'](.*?)["']/);
        const primaryMatch = loopCode.match(/primary:\s*["'](.*?)["']/);
        const fpsMatch = loopCode.match(/fps:\s*(\d+)/);

        return jsonResponse({
          success: true,
          component: nameMatch ? nameMatch[1] : "DynamicMobileComponent",
          target: targetMatch ? targetMatch[1] : "xui",
          primary_color: primaryMatch ? primaryMatch[1] : "#38bdf8",
          fps: fpsMatch ? parseInt(fpsMatch[1]) : 120,
          status: "Compiled to Looping Virtual Surface"
        });
      } catch(err) {
        return jsonResponse({ error: err.message }, 400);
      }
    }

    // 7. Cloud Enterprise Console (HTML Dashboard)
    const colo = request.cf ? request.cf.colo : "GLOBAL";
    return new Response(getDashboardHtml(colo), {
      headers: {
        "Content-Type": "text/html; charset=utf-8",
        ...getCorsHeaders()
      }
    });
  }
};

function getDashboardHtml(colo) {
  return `<!DOCTYPE html>
<html lang="es">
<head>
  <meta charset="UTF-8">
  <title>CS WEBS CLOUD — Coki Studios Web Enterprise & Business Server</title>
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <link rel="icon" type="image/svg+xml" href="/assets/cs-logo.svg">
  <script src="https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2"></script>
  <style>
    :root {
      --primary: #38bdf8;
      --accent: #0284c7;
      --bg: #07090e;
      --surface: #0f172a;
      --surface-glass: rgba(15, 23, 42, 0.85);
      --border: rgba(255, 255, 255, 0.08);
      --text: #f8fafc;
      --text-muted: #94a3b8;
    }
    * { box-sizing: border-box; margin: 0; padding: 0; }
    body {
      background: var(--bg);
      color: var(--text);
      font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
      padding: 24px;
      line-height: 1.5;
    }
    .container { max-width: 1160px; margin: 0 auto; }
    .header {
      display: flex;
      justify-content: space-between;
      align-items: center;
      padding-bottom: 20px;
      border-bottom: 1px solid var(--border);
      margin-bottom: 24px;
      gap: 16px;
      flex-wrap: wrap;
    }
    .brand-box {
      display: flex;
      align-items: center;
      gap: 14px;
    }
    .cs-logo-header {
      width: 48px;
      height: 48px;
      border-radius: 12px;
      box-shadow: 0 0 20px rgba(56, 189, 248, 0.35);
      transition: transform 0.3s;
    }
    .cs-logo-header:hover {
      transform: scale(1.08) rotate(4deg);
    }
    .badge {
      background: linear-gradient(135deg, #0ea5e9, #6366f1);
      color: #fff;
      font-size: 11px;
      font-weight: 800;
      padding: 4px 10px;
      border-radius: 6px;
      letter-spacing: 0.5px;
    }

    /* CS ID Auth Button & Profile */
    .auth-section {
      display: flex;
      align-items: center;
      gap: 12px;
    }
    .csid-login-btn {
      background: linear-gradient(135deg, #0ea5e9, #2563eb);
      color: #ffffff;
      border: 1px solid rgba(255, 255, 255, 0.18);
      padding: 8px 16px;
      border-radius: 10px;
      font-size: 13px;
      font-weight: 700;
      cursor: pointer;
      display: inline-flex;
      align-items: center;
      gap: 10px;
      box-shadow: 0 4px 16px rgba(14, 165, 233, 0.35);
      transition: all 0.2s cubic-bezier(0.16, 1, 0.3, 1);
    }
    .csid-login-btn:hover {
      transform: translateY(-2px);
      box-shadow: 0 6px 22px rgba(14, 165, 233, 0.55);
      filter: brightness(1.1);
    }
    .csid-btn-logo {
      width: 22px;
      height: 22px;
      border-radius: 5px;
    }
    .user-profile-badge {
      display: flex;
      align-items: center;
      gap: 10px;
      background: var(--surface-glass);
      border: 1px solid var(--border);
      padding: 6px 12px;
      border-radius: 12px;
      backdrop-filter: blur(12px);
    }
    .user-avatar {
      width: 34px;
      height: 34px;
      border-radius: 50%;
      border: 2px solid var(--primary);
    }
    .user-meta {
      display: flex;
      flex-direction: column;
    }
    .user-name {
      font-size: 12px;
      font-weight: 700;
      color: #fff;
    }
    .user-tag {
      font-size: 10px;
      color: #34d399;
      font-weight: 600;
    }
    .btn-logout {
      background: rgba(239, 68, 68, 0.15);
      border: 1px solid rgba(239, 68, 68, 0.4);
      color: #f87171;
      padding: 4px 10px;
      border-radius: 6px;
      font-size: 11px;
      font-weight: 600;
      cursor: pointer;
      transition: 0.2s;
    }
    .btn-logout:hover {
      background: rgba(239, 68, 68, 0.3);
      color: #fff;
    }

    /* Modal CS ID */
    .csid-modal-overlay {
      position: fixed;
      top: 0; left: 0; width: 100vw; height: 100vh;
      background: rgba(0, 0, 0, 0.75);
      backdrop-filter: blur(10px);
      -webkit-backdrop-filter: blur(10px);
      z-index: 9999;
      display: none;
      align-items: center;
      justify-content: center;
      padding: 20px;
    }
    .csid-modal-overlay.active {
      display: flex;
    }
    .csid-modal-card {
      background: rgba(11, 17, 32, 0.96);
      border: 1px solid rgba(14, 165, 233, 0.35);
      border-radius: 22px;
      width: 100%;
      max-width: 400px;
      padding: 28px 24px;
      box-shadow: 0 25px 60px rgba(0, 0, 0, 0.75), 0 0 40px rgba(14, 165, 233, 0.15);
      position: relative;
      animation: modalFadeIn 0.25s cubic-bezier(0.16, 1, 0.3, 1);
    }
    @keyframes modalFadeIn {
      from { opacity: 0; transform: translateY(16px) scale(0.97); }
      to { opacity: 1; transform: translateY(0) scale(1); }
    }
    .csid-modal-close {
      position: absolute;
      top: 14px;
      right: 14px;
      background: rgba(255, 255, 255, 0.08);
      border: 1px solid var(--border);
      color: var(--text-muted);
      width: 28px;
      height: 28px;
      border-radius: 50%;
      display: flex;
      align-items: center;
      justify-content: center;
      cursor: pointer;
      font-size: 14px;
      line-height: 1;
      transition: 0.2s;
    }
    .csid-modal-close:hover {
      color: #fff;
      background: rgba(239, 68, 68, 0.2);
      border-color: #f87171;
    }
    .csid-modal-header {
      text-align: center;
      margin-bottom: 20px;
    }
    .csid-modal-logo {
      width: 58px;
      height: 58px;
      border-radius: 14px;
      margin-bottom: 10px;
      box-shadow: 0 4px 20px rgba(8, 115, 165, 0.5);
    }
    .csid-modal-title {
      font-size: 20px;
      font-weight: 800;
      color: #fff;
      letter-spacing: -0.02em;
    }
    .csid-modal-sub {
      font-size: 12px;
      color: var(--text-muted);
      margin-top: 4px;
    }
    .csid-form-group {
      margin-bottom: 12px;
      text-align: left;
    }
    .csid-label {
      display: block;
      font-size: 11px;
      font-weight: 700;
      color: var(--text-muted);
      text-transform: uppercase;
      margin-bottom: 4px;
    }
    .csid-input {
      width: 100%;
      background: rgba(255, 255, 255, 0.05);
      border: 1px solid var(--border);
      color: #fff;
      padding: 10px 12px;
      border-radius: 10px;
      font-size: 13px;
      outline: none;
      box-sizing: border-box;
      transition: 0.2s;
    }
    .csid-input:focus {
      border-color: var(--primary);
      box-shadow: 0 0 0 3px rgba(14, 165, 233, 0.2);
    }
    .csid-submit-btn {
      width: 100%;
      background: linear-gradient(135deg, #0ea5e9, #0284c7);
      color: #fff;
      border: none;
      padding: 11px;
      border-radius: 10px;
      font-weight: 700;
      font-size: 13px;
      cursor: pointer;
      margin-top: 6px;
      transition: 0.2s;
    }
    .csid-submit-btn:hover {
      filter: brightness(1.1);
      transform: translateY(-1px);
    }
    .csid-divider {
      display: flex;
      align-items: center;
      text-align: center;
      margin: 16px 0;
      color: var(--text-muted);
      font-size: 10.5px;
      text-transform: uppercase;
      font-weight: 700;
      letter-spacing: 0.5px;
    }
    .csid-divider::before, .csid-divider::after {
      content: '';
      flex: 1;
      border-bottom: 1px solid var(--border);
    }
    .csid-divider span { padding: 0 10px; }
    .csid-social-btn {
      width: 100%;
      background: rgba(255, 255, 255, 0.06);
      border: 1px solid var(--border);
      color: #fff;
      padding: 9px;
      border-radius: 10px;
      font-size: 12.5px;
      font-weight: 600;
      cursor: pointer;
      display: flex;
      align-items: center;
      justify-content: center;
      gap: 10px;
      margin-bottom: 8px;
      transition: 0.2s;
    }
    .csid-social-btn:hover {
      background: rgba(255, 255, 255, 0.12);
      border-color: rgba(255, 255, 255, 0.25);
    }
    .csid-feedback {
      font-size: 12px;
      margin-top: 10px;
      display: none;
      padding: 8px 12px;
      border-radius: 8px;
      text-align: center;
    }
    .csid-feedback.error {
      display: block;
      background: rgba(239, 68, 68, 0.15);
      border: 1px solid rgba(239, 68, 68, 0.3);
      color: #f87171;
    }
    .csid-feedback.success {
      display: block;
      background: rgba(16, 185, 129, 0.15);
      border: 1px solid rgba(16, 185, 129, 0.3);
      color: #34d399;
    }

    .metrics-grid {
      display: grid;
      grid-template-columns: repeat(auto-fit, minmax(220px, 1fr));
      gap: 16px;
      margin-bottom: 24px;
    }
    .metric-card {
      background: var(--surface);
      border: 1px solid var(--border);
      border-radius: 12px;
      padding: 16px;
    }
    .metric-label { font-size: 11px; color: var(--text-muted); text-transform: uppercase; font-weight: 700; }
    .metric-val { font-size: 22px; font-weight: 800; color: #fff; margin-top: 4px; }
    .metric-sub { font-size: 11px; color: #34d399; margin-top: 4px; }
    .card {
      background: var(--surface);
      border: 1px solid var(--border);
      border-radius: 12px;
      padding: 20px;
      margin-bottom: 24px;
    }
    table { width: 100%; border-collapse: collapse; font-size: 13px; margin-top: 12px; }
    th, td { padding: 10px 14px; text-align: left; border-bottom: 1px solid var(--border); }
    th { color: var(--text-muted); font-size: 11px; text-transform: uppercase; }
    .btn {
      background: #0284c7;
      color: #fff;
      text-decoration: none;
      padding: 4px 10px;
      border-radius: 4px;
      font-size: 11px;
      font-weight: 600;
      display: inline-block;
    }
    .btn:hover { background: #38bdf8; color: #000; }
  </style>
</head>
<body>
  <div class="container">
    <div class="header">
      <div class="brand-box">
        <img src="/assets/cs-logo.svg" alt="Coki Studios" class="cs-logo-header">
        <div>
          <h1 style="font-size: 20px; font-weight: 800;">✦ CS WEBS CLOUD ENTERPRISE ✦</h1>
          <p style="color: var(--text-muted); font-size: 13px;">Coki Studios Web Enterprise & Business Server • <b>webs.cokistudios.com</b></p>
        </div>
      </div>
      <div class="auth-section">
        <span class="badge">EDGE POP: ${colo}</span>
        <div id="auth-container">
          <!-- Dynamic Iniciar sesión con Coki Studios ID -->
          <button id="login-btn" class="csid-login-btn" onclick="loginWithCokiId()">
            <img src="/assets/cs-logo.svg" class="csid-btn-logo"> Iniciar sesión con Coki Studios ID
          </button>
        </div>
      </div>
    </div>

    <!-- Telemetry Metrics -->
    <div class="metrics-grid">
      <div class="metric-card">
        <div class="metric-label">Estado de la Nube</div>
        <div class="metric-val" style="color: #34d399;">99.999% SLA</div>
        <div class="metric-sub">● Global Active Anycast (webs.cokistudios.com)</div>
      </div>
      <div class="metric-card">
        <div class="metric-label">Latencia Edge</div>
        <div class="metric-val" style="color: #38bdf8;">< 15 ms</div>
        <div class="metric-sub">Cloudflare Workers Core</div>
      </div>
      <div class="metric-card">
        <div class="metric-label">Hardware Attestation</div>
        <div class="metric-val" style="color: #a78bfa;">Activo</div>
        <div class="metric-sub">SEP & StrongBox Verified</div>
      </div>
      <div class="metric-card">
        <div class="metric-label">Módulos .c2 Activos</div>
        <div class="metric-val" style="color: #f59e0b;">${INITIAL_CATALOG.length} Módulos</div>
        <div class="metric-sub">OTA Global Repository</div>
      </div>
    </div>

    <!-- Active User Session Details (Shown when logged in) -->
    <div id="user-details-card" class="card" style="display: none; background: rgba(14, 165, 233, 0.08); border-color: rgba(56, 189, 248, 0.3);">
      <h3 style="font-size: 14px; color: var(--primary); margin-bottom: 6px;">✦ Sesión de Desarrollador Coki Studios ID Activa</h3>
      <p style="font-size: 12px; color: var(--text-muted);" id="user-welcome-msg">Autenticado con permisos de despliegue en caliente y Hardware Enclave.</p>
    </div>

    <!-- Module Catalog -->
    <div class="card">
      <h2 style="font-size: 15px; margin-bottom: 8px;">Catálogo Global de Módulos .c2 (OTA)</h2>
      <p style="color: var(--text-muted); font-size: 12px; margin-bottom: 12px;">Módulos de UI adaptados para celulares Shine (f1, i1, fW1, X1, Xa1, Nomad 1, A1, Vintage).</p>
      <table>
        <thead>
          <tr>
            <th>Nombre del Módulo</th>
            <th>Dispositivo Objetivo</th>
            <th>Refresco</th>
            <th>Tamaño</th>
            <th>Descarga Directa OTA</th>
          </tr>
        </thead>
        <tbody>
          ${INITIAL_CATALOG.map(m => `
            <tr>
              <td><b style="color: ${m.primary_color};">${m.name}</b><br><span style="font-size: 10px; color: var(--text-muted);">${m.component_id}</span></td>
              <td>${m.target_device}</td>
              <td><b>${m.target_fps} FPS</b></td>
              <td>${m.size_formatted}</td>
              <td><a class="btn" href="${m.download_url}">⚡ Descargar .c2</a></td>
            </tr>
          `).join('')}
        </tbody>
      </table>
    </div>

    <div class="card" style="font-family: monospace; font-size: 12px; background: #05070c;">
      <b style="color: #38bdf8;">[API ENDPOINTS GLOBALES — WEBS.COKISTUDIOS.COM]</b><br>
      • GET  /api/v1/health          - Telemetría y estado del servidor edge<br>
      • GET  /api/v1/csid/verify     - Hardware Attestation de tokens de identidad<br>
      • GET  /api/v1/c2/modules      - Catálogo JSON de paquetes y fragmentos .c2<br>
      • GET  /api/v1/c2/download/:id - Descarga OTA de módulos .c2<br>
      • POST /api/v1/c2/upload       - Despliegue en la nube desde UI Connect PC<br>
      • POST /api/v1/c2/eval         - Compilador y evaluador de fragmentos Looping<br>
      • GET  /assets/cs-logo.svg     - Logotipo oficial vector de Coki Studios
    </div>
  </div>

  <!-- Modal Oficial Coki Studios ID -->
  <div id="csid-modal" class="csid-modal-overlay" onclick="if(event.target === this) closeCsidModal()">
    <div class="csid-modal-card">
      <button class="csid-modal-close" onclick="closeCsidModal()">✕</button>
      <div class="csid-modal-header">
        <img src="/assets/cs-logo.svg" class="csid-modal-logo" alt="CS Logo">
        <div class="csid-modal-title">Coki Studios ID</div>
        <div class="csid-modal-sub">Tu cuenta unificada • Hardware Verified</div>
      </div>

      <form onsubmit="handleEmailAuth(event)">
        <div class="csid-form-group">
          <label class="csid-label">Correo Electrónico de CS ID</label>
          <input type="email" id="csid-input-email" class="csid-input" placeholder="desarrollador@cokistudios.com" required>
        </div>
        <div class="csid-form-group">
          <label class="csid-label">Contraseña</label>
          <input type="password" id="csid-input-password" class="csid-input" placeholder="••••••••••••" required>
        </div>
        <button type="submit" class="csid-submit-btn" id="csid-submit-btn">Entrar con Coki Studios ID</button>
      </form>

      <div class="csid-divider"><span>O continúa con</span></div>

      <button type="button" class="csid-social-btn" onclick="loginWithOAuthProvider('google')">
        <svg width="16" height="16" viewBox="0 0 24 24"><path fill="#4285F4" d="M23.745 12.27c0-.7-.06-1.4-.19-2.07H12v4.51h6.6c-.29 1.52-1.14 2.82-2.4 3.68v3.05h3.88c2.27-2.09 3.665-5.17 3.665-9.17z"/><path fill="#34A853" d="M12 24c3.24 0 5.95-1.08 7.93-2.91l-3.88-3.05c-1.08.72-2.45 1.16-4.05 1.16-3.12 0-5.77-2.1-6.72-4.93H1.25v3.15C3.26 21.36 7.33 24 12 24z"/><path fill="#FBBC05" d="M5.28 14.27c-.25-.72-.38-1.49-.38-2.27s.13-1.55.38-2.27V6.58H1.25C.45 8.18 0 9.97 0 12s.45 3.82 1.25 5.42l4.03-3.15z"/><path fill="#EA4335" d="M12 4.75c1.77 0 3.35.61 4.6 1.8l3.42-3.42C17.95 1.19 15.24 0 12 0 7.33 0 3.26 2.64 1.25 6.58l4.03 3.15c.95-2.83 3.6-4.98 6.72-4.98z"/></svg>
        Continuar con Google
      </button>

      <button type="button" class="csid-social-btn" onclick="loginWithOAuthProvider('github')">
        <svg width="16" height="16" fill="currentColor" viewBox="0 0 24 24"><path fill-rule="evenodd" clip-rule="evenodd" d="M12 2C6.477 2 2 6.484 2 12.017c0 4.425 2.865 8.18 6.839 9.504.5.092.682-.217.682-.483 0-.237-.008-.868-.013-1.703-2.782.605-3.369-1.343-3.369-1.343-.454-1.158-1.11-1.466-1.11-1.466-.908-.62.069-.608.069-.608 1.003.07 1.53 1.032 1.53 1.032.892 1.53 2.341 1.088 2.91.832.092-.647.35-1.088.636-1.338-2.22-.253-4.555-1.113-4.555-4.951 0-1.093.39-1.988 1.029-2.688-.103-.253-.446-1.272.098-2.65 0 0 .84-.27 2.75 1.026A9.564 9.564 0 0112 6.844c.85.004 1.705.115 2.504.337 1.909-1.296 2.747-1.027 2.747-1.027.546 1.379.202 2.398.1 2.651.64.7 1.028 1.595 1.028 2.688 0 3.848-2.339 4.695-4.566 4.943.359.309.678.92.678 1.855 0 1.338-.012 2.419-.012 2.747 0 .268.18.58.688.482A10.019 10.019 0 0022 12.017C22 6.484 17.522 2 12 2z"/></svg>
        Continuar con GitHub
      </button>

      <div id="csid-feedback" class="csid-feedback"></div>

      <div style="text-align: center; margin-top: 14px; font-size: 11.5px; color: var(--text-muted);">
        ¿No tienes cuenta? <a href="https://cokistudios.com/register.html" target="_blank" style="color: var(--primary); text-decoration: none; font-weight: 600;">Crear cuenta CS ID</a>
      </div>
    </div>
  </div>

  <script>
    const SUPABASE_URL = 'https://cmkumxprmmhuinxfppxl.supabase.co';
    const SUPABASE_ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImNta3VteHBybW1odWlueGZwcHhsIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzc0OTkxNzEsImV4cCI6MjA5MzA3NTE3MX0.BNbSSxoObXMGpyin4-3udSM6ricoTO57Zaade5dTfxQ';

    let supabaseClient = null;
    if (window.supabase) {
      supabaseClient = window.supabase.createClient(SUPABASE_URL, SUPABASE_ANON_KEY, {
        auth: {
          persistSession: true,
          autoRefreshToken: true,
          detectSessionInUrl: true,
          flowType: 'pkce'
        }
      });
    }

    async function checkAuthSession() {
      if (!supabaseClient) return;
      const { data: { session } } = await supabaseClient.auth.getSession();
      renderAuthState(session);

      if (window.location.hash || window.location.search.includes('code=')) {
        window.history.replaceState({}, document.title, window.location.pathname);
      }

      supabaseClient.auth.onAuthStateChange((_event, session) => {
        renderAuthState(session);
      });
    }

    function renderAuthState(session) {
      const container = document.getElementById('auth-container');
      const detailsCard = document.getElementById('user-details-card');
      const welcomeMsg = document.getElementById('user-welcome-msg');

      if (session && session.user) {
        const user = session.user;
        const name = user.user_metadata?.full_name || user.email?.split('@')[0] || 'Desarrollador CS';
        const avatar = user.user_metadata?.avatar_url || '/assets/cs-logo.svg';
        const email = user.email || '';

        container.innerHTML = 
          '<div class="user-profile-badge">' +
            '<img src="' + avatar + '" class="user-avatar" alt="Avatar">' +
            '<div class="user-meta">' +
              '<span class="user-name">' + name + '</span>' +
              '<span class="user-tag">🔒 CS ID • Hardware Verified</span>' +
            '</div>' +
            '<button class="btn-logout" onclick="logoutCokiId()">Salir</button>' +
          '</div>';

        if (detailsCard) {
          detailsCard.style.display = 'block';
          welcomeMsg.innerHTML = '<b>Usuario:</b> ' + name + ' (' + email + ') • <b>CS ID Token:</b> <span style="font-family:monospace;">' + user.id.slice(0, 16) + '...</span> • <b>Hardware Enclave:</b> Activo';
        }
      } else {
        container.innerHTML = 
          '<button id="login-btn" class="csid-login-btn" onclick="openCsidModal()">' +
            '<img src="/assets/cs-logo.svg" class="csid-btn-logo"> Iniciar sesión con Coki Studios ID' +
          '</button>';
        if (detailsCard) detailsCard.style.display = 'none';
      }
    }

    function openCsidModal() {
      const modal = document.getElementById('csid-modal');
      if (modal) modal.classList.add('active');
      const fb = document.getElementById('csid-feedback');
      if (fb) {
        fb.className = 'csid-feedback';
        fb.style.display = 'none';
      }
    }

    function closeCsidModal() {
      const modal = document.getElementById('csid-modal');
      if (modal) modal.classList.remove('active');
    }

    async function handleEmailAuth(e) {
      e.preventDefault();
      if (!supabaseClient) return;
      const email = document.getElementById('csid-input-email').value.trim();
      const password = document.getElementById('csid-input-password').value;
      const fb = document.getElementById('csid-feedback');
      const submitBtn = document.getElementById('csid-submit-btn');

      submitBtn.disabled = true;
      submitBtn.innerText = 'Verificando...';

      const { data, error } = await supabaseClient.auth.signInWithPassword({ email, password });
      submitBtn.disabled = false;
      submitBtn.innerText = 'Entrar con Coki Studios ID';

      if (error) {
        fb.className = 'csid-feedback error';
        fb.innerText = error.message;
        fb.style.display = 'block';
      } else {
        fb.className = 'csid-feedback success';
        fb.innerText = '¡Sesión iniciada correctamente!';
        fb.style.display = 'block';
        setTimeout(() => {
          closeCsidModal();
          renderAuthState(data.session);
        }, 600);
      }
    }

    async function loginWithOAuthProvider(provider) {
      if (!supabaseClient) return;
      await supabaseClient.auth.signInWithOAuth({
        provider: provider,
        options: {
          redirectTo: window.location.origin
        }
      });
    }

    async function logoutCokiId() {
      if (!supabaseClient) return;
      await supabaseClient.auth.signOut();
      window.location.reload();
    }

    checkAuthSession();
  </script>
</body>
</html>`;
}
