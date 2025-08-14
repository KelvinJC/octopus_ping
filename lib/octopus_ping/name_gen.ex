defmodule OctopusPing.NameGen do
  @adjectives ~w(bright dark swift slow quiet loud bold timid lucky fated crimson rouge silver black icy rocky electric hot)
  @nouns ~w(octopus orca comet star lantern lamp meadow fauna raven crow falcon osprey tide avalanche summit valley ember coal)

  def generate do
    adj = Enum.random(@adjectives)
    noun = Enum.random(@nouns)
    num = :rand.uniform(9999)
    "#{adj}-#{noun}-#{num}"
  end
end
