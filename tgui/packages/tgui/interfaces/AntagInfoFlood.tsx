import { useState } from 'react';
import { LabeledList, Section, Stack, Tabs } from 'tgui-core/components';
import { BooleanLike } from 'tgui-core/react';

import { useBackend } from '../backend';
import { Window } from '../layouts';
import {
  Objective,
  ObjectivePrintout,
  ReplaceObjectivesButton,
} from './common/Objectives';

type Form = 'Combat' | 'Carrier' | 'Constructor' | 'Overseer';
type GuideTab = 'Overview' | Form;
type GuideEntry = { label: string; text: string };
type Guide = { summary: string; entries: GuideEntry[] };

type Data = {
  current_form?: Form;
  objectives: Objective[];
  can_change_objective: BooleanLike;
};

const tabs: GuideTab[] = [
  'Overview',
  'Combat',
  'Carrier',
  'Constructor',
  'Overseer',
];

const guides: Record<Form, Guide> = {
  Combat: {
    summary: 'Fight for the infestation and evolve into a specialized Flood unit.',
    entries: [
      {
        label: 'Equipment',
        text: 'Flood Combat spawns empty-handed. You can pick up and use ordinary station equipment and guns. AI Flood Combat may scavenge guns; no normal spawn starts with one.',
      },
      {
        label: 'Evolution',
        text: 'Use Evolve Flood to become a Flood Carrier or Flood Constructor. Constructors can become overseers when the hive has no living overseer and the death penalty has ended. Flood Combat cannot produce infectors directly.',
      },
      {
        label: 'Infected hosts',
        text: 'A converted human, including a lizard, keeps their original name and becomes an empty-handed Flood Combat. Infected monkeys and other animals become Flood Carriers. Their gear drops on the floor, and a player-controlled converted unit has extra health.',
      },
      {
        label: 'Attacks',
        text: 'Your melee attacks damage targets but never infect them. Infection requires a Flood Infector attached to a dead human or animal.',
      },
    ],
  },
  Carrier: {
    summary: 'Bring a swarm into a fight and rupture to release it.',
    entries: [
      {
        label: 'Release',
        text: 'Use Release Infectors to burst immediately. Attacking in melee or dying also bursts the carrier. Bursting destroys your carrier body.',
      },
      {
        label: 'Swarm',
        text: 'A burst releases 6 to 12 AI Flood Infectors onto nearby open tiles, along with a small Reactive Spines smoke cloud.',
      },
      {
        label: 'AI behavior',
        text: 'An uncontrolled carrier bursts when it gets within three tiles of a visible target it is pursuing, before making melee contact.',
      },
      {
        label: 'After bursting',
        text: 'Flood Infectors are AI-controlled and cannot be taken over through the ghost spawner menu. Protect them as they latch onto hosts.',
      },
    ],
  },
  Constructor: {
    summary: 'Build the infestation on the floor beneath you.',
    entries: [
      {
        label: 'Infest Floor',
        text: 'Cover the floor you stand on with Flood growth every five seconds. It does not replace ordinary station walls or airlocks. Flood units slowly heal while standing on this floor.',
      },
      {
        label: 'Grow Biomass',
        text: 'Create a small biomass spawner on your tile every 60 seconds. Spawners spread growth and produce Flood Carriers 80% of the time or Flood Combat 20% of the time while limiting their nearby population. Flood and ghosts can see the countdown to the next spawn attempt.',
      },
      {
        label: 'Structures',
        text: 'Build a solid wall, a door, or a translucent membrane on your tile. Each structure has a 15-second cooldown; successful construction also has a shared two-second recovery. AI constructors spread Flood floors without building these structures.',
      },
      {
        label: 'Produce Infector',
        text: 'Bud off one AI Flood Infector every 45 seconds. Uncontrolled constructors also produce them over time.',
      },
      {
        label: 'Grow Spore Cluster',
        text: 'Place a cluster on your tile every 180 seconds. When a human passes through it, the cluster bursts after two seconds and releases four Flood Infectors. Too many nearby clusters block placement.',
      },
      {
        label: 'Become Overseer',
        text: 'Only one living overseer can exist at a time. After one dies, the hive must recover for four minutes before any constructor can become the new overseer.',
      },
    ],
  },
  Overseer: {
    summary: 'Grow the nest and command nearby AI Flood units.',
    entries: [
      {
        label: 'Infest Floor',
        text: 'Cover the floor you stand on with Flood growth every five seconds, like a constructor.',
      },
      {
        label: 'Create Flood units',
        text: 'Create a Flood Constructor every 30 seconds or a Flood Carrier every 120 seconds. Both appear on your tile as separate AI units.',
      },
      {
        label: 'Direct Infestation Growth',
        text: 'Spread growth to up to three nearby floor tiles with a 30-second cooldown.',
      },
      {
        label: 'Overseer Mode',
        text: 'Stand on Flood-covered floor and toggle Overseer Mode. Your viewpoint can move across Flood biomass while your physical body remains in place and vulnerable. Other Flood players can see your marker.',
      },
      {
        label: 'Middle-click orders',
        text: 'In Overseer Mode, middle-click a living human within 15 tiles of your view to direct nearby AI Flood units, including infectors, to attack them. Middle-click a floor tile to rally those units there. Player-controlled units are unaffected.',
      },
      {
        label: 'Death',
        text: 'Your death shocks the hive for four minutes. Surviving Flood briefly stop, move more slowly, and lose Flood Chorus until a new overseer can emerge.',
      },
    ],
  },
};

export const AntagInfoFlood = () => {
  const { data } = useBackend<Data>();
  const { current_form, objectives = [], can_change_objective } = data;
  const [tab, setTab] = useState<GuideTab>(current_form || 'Overview');

  return (
    <Window width={720} height={620} theme="flood">
      <Window.Content>
        <Stack vertical fill>
          <Stack.Item>
            <Tabs fluid>
              {tabs.map((guideTab) => (
                <Tabs.Tab
                  key={guideTab}
                  selected={tab === guideTab}
                  onClick={() => setTab(guideTab)}
                >
                  {guideTab === current_form ? `${guideTab} (you)` : guideTab}
                </Tabs.Tab>
              ))}
            </Tabs>
          </Stack.Item>
          <Stack.Item grow>
            <Section
              fill
              scrollable
              title={tab === 'Overview' ? 'The Flood' : `Flood ${tab}`}
            >
              {tab === 'Overview' ? (
                <Stack vertical>
                  <Stack.Item>
                    Expand the infestation, protect corpses for your infectors,
                    and establish Flood biomass. You share Floodmind
                    speech nearby with :f, and Flood Chorus reaches every active
                    Flood player.
                  </Stack.Item>
                  <Stack.Item>
                    <Section title="Flood Infectors (AI allies)">
                      Flood Infectors cannot be taken over from the ghost spawner.
                      They leap onto humans or animals and remain buckled to
                      them. Against living hosts, they deal 10 brute every two
                      seconds; the host can resist or the infector can be killed
                      to break the latch. Only a dead host can be converted,
                      after five seconds attached to the corpse. Their swarms
                      can merge, and an unlatched infector can reanimate a fallen
                      Flood Combat once. Dying infectors also release a small
                      Reactive Spines smoke cloud.
                    </Section>
                  </Stack.Item>
                  <Stack.Item>
                    <Section title="Biomass and fire">
                      Flood units heal slowly only while standing on
                      Flood-covered floor. Enough fire damage gibs Flood
                      bodies. Fire can destroy biomass; crew can also clear
                      floor growth with a welder or by removing the floor.
                    </Section>
                  </Stack.Item>
                  <Stack.Item>
                    <ObjectivePrintout
                      objectives={objectives}
                      objectiveFollowup={
                        <ReplaceObjectivesButton
                          can_change_objective={can_change_objective}
                          button_title="Change Objective"
                          button_colour="yellow"
                        />
                      }
                    />
                  </Stack.Item>
                </Stack>
              ) : (
                <Stack vertical>
                  <Stack.Item>{guides[tab].summary}</Stack.Item>
                  <Stack.Item>
                    <LabeledList>
                      {guides[tab].entries.map((entry) => (
                        <LabeledList.Item key={entry.label} label={entry.label}>
                          {entry.text}
                        </LabeledList.Item>
                      ))}
                    </LabeledList>
                  </Stack.Item>
                </Stack>
              )}
            </Section>
          </Stack.Item>
        </Stack>
      </Window.Content>
    </Window>
  );
};
