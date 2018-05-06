#!/bin/elixir

defmodule IncrementalGame do
	@esc "\x1B["
	@suffixes [""] ++ ~w(K M B T Qa Qt Sx Sp Oc Nn Dc UDc DDc TDc QaDC QtDC QnDC)
	@defaultIncrement 1.15
	@buildings [
		%{ name: "A", baseCost: 1.0e1 , amplify: 1.0e-1 },
		%{ name: "B", baseCost: 1.0e3 , amplify: 1.0e0  },
		%{ name: "C", baseCost: 1.0e6 , amplify: 1.0e2  },
		%{ name: "D", baseCost: 1.0e10, amplify: 1.0e5  },
		%{ name: "E", baseCost: 1.0e15, amplify: 1.0e9  },
	]


	def clearScreen do
		IO.puts "#{@esc}2J#{@esc}H"
	end

	def printNumber(num), do: printNumber(num, @suffixes)
	def printNumber(_, []), do: "inf"
	def printNumber(num, [suffix | suffixes]) do
		if num>=1.0e3 do
			printNumber(num/1.0e3, suffixes)
		else
			Float.round(num/1,2) |> to_string |> Kernel.<>(suffix)
		end
	end

	def calculateCost(%{baseCost: baseCost, costIncrement: costIncrement, owned: owned}) do
		baseCost * :math.pow(costIncrement, owned)
	end
	def calculateCost(bldg = %{baseCost: _, owned: _}), do: bldg |> Map.put(:costIncrement, @defaultIncrement) |> calculateCost()
	
	def playRound() do
		playRound(%{
			score: 0,
			buildings: Enum.map(@buildings, fn(bldg) -> Map.put(bldg, :owned, 0) end)
		})
	end
	
	def playRound(%{score: score, buildings: buildings}) do
		clearScreen()

		Enum.each buildings, fn(bldg) ->
			cost = calculateCost(bldg)
			IO.puts "Building #{bldg.name} costs #{printNumber cost}"
		end
		
		IO.gets "\nScore is #{printNumber score}. Also, #{printNumber (Enum.at @buildings, 1).baseCost}"
		playRound(%{score: score+1, buildings: buildings})
	end
end

IncrementalGame.playRound()