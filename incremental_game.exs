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

	def vt100(code), do: IO.write @esc <> code
	
	def clearScreen do
		vt100 "2J"
		vt100 "H"
	end

	def printNumber(num), do: printNumber(num, @suffixes)
	def printNumber(_, []), do: "inf" # After the list of named suffixes gets exhausted, give up and call the number infinite.
	def printNumber(num, [suffix | suffixes]) do
		if num>=1.0e3 do
			printNumber(num/1.0e3, suffixes)
		else
			Float.round(num/1,2) |> to_string |> Kernel.<>(suffix)
		end
	end

	def calculateClickPower(buildings) do
		Enum.reduce buildings, 1, fn(bldg, acc) ->
			acc + bldg.amplify * bldg.owned
		end
	end

	def calculateCost(%{baseCost: baseCost, costIncrement: costIncrement, owned: owned}) do
		baseCost * :math.pow(costIncrement, owned)
	end
	def calculateCost(bldg = %{baseCost: _, owned: _}), do: bldg |> Map.put(:costIncrement, @defaultIncrement) |> calculateCost()

	def buyBuildings(qty, score, bldg) when qty<1, do: [score, bldg]
	def buyBuildings(qty, score, bldg) do
		cost = calculateCost(bldg)
		if cost < score do
			buyBuildings(qty-1, score - cost, %{bldg | owned: bldg.owned+1})
		else
			buyBuildings(0, score, bldg)
		end
	end
	
	def playRound() do
		playRound(%{
			score: 0,
			buildings: Enum.map(@buildings, fn(bldg) -> Map.put(bldg, :owned, 0) end)
		})
	end

	def playRound(%{score: score, buildings: buildings}) do
		clearScreen()

#%{score: score, buildings: buildings} |> inspect |> IO.puts
		
		Enum.each buildings, fn(bldg) ->
			cost = calculateCost(bldg)
			if score < cost, do: vt100("31m"), else: vt100("32;1m")
			IO.puts "#{bldg.name} costs #{printNumber cost}.\t"
				<> "You own #{printNumber bldg.owned} of them currently."
			vt100("0m")
		end
		
		clickPower = calculateClickPower(buildings)
		IO.puts "Score: \t#{printNumber score}"
		IO.puts "Click Power: \t#{printNumber clickPower}"
		cmd = IO.gets ">"
		score = score + clickPower
		
		Enum.reduce(
			:lists.reverse(buildings),
			%{score: score, buildings: []},
			fn(bldg, %{score: score, buildings: newbuildings}) ->
				qty = case(Regex.run ~r"\b((\d+)\s*)?#{bldg.name}\b"iu, cmd) do
					[_, _, qtyText] ->
						case String.to_integer qtyText do
							qty when qty>1.0e3 -> 1.0e3
							qty -> qty
						end
					[_] -> 1
					_ -> 0 # nil, or any other permutation I haven't accounted for indicate no copies of presently inspected building are being bought.
				end
				[score, bldg] = buyBuildings(qty, score, bldg)
				%{score: score, buildings: [bldg | newbuildings]}
			end
		) |> playRound()

	end
end

IncrementalGame.playRound()