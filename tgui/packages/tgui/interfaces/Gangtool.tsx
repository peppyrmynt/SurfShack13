import {
  Box,
  Button,
  LabeledList,
  NoticeBox,
  Section,
  Stack,
} from 'tgui-core/components';
import { BooleanLike } from 'tgui-core/react';

import { useBackend } from '../backend';
import { Window } from '../layouts';
import { GenericUplink, Item } from './Uplink/GenericUplink';

type GangItem = {
  id: string;
  name: string;
  cost: string;
  desc: string;
  icon: string;
  icon_state: string;
  can_buy: BooleanLike;
};

type ShopCategory = {
  name: string;
  items: GangItem[];
};

type Data = {
  vigilante: BooleanLike;
  personal?: BooleanLike;
  title: string;
  registered: BooleanLike;
  is_leader?: BooleanLike;
  promotable?: BooleanLike;
  positions_open?: BooleanLike;
  points: number;
  currency: string;
  gang_name?: string;
  gang_color?: string;
  members?: number;
  territories?: number;
  control?: number;
  next_payout?: number;
  dominating?: BooleanLike;
  dom_time_left?: number;
  dom_attempts?: number;
  recalls?: number;
  held_item?: string;
  held_value?: number;
  categories: ShopCategory[];
};

const formatTime = (seconds = 0) => {
  const minutes = Math.floor(seconds / 60);
  const rest = Math.floor(seconds % 60);
  return `${minutes}:${rest < 10 ? '0' : ''}${rest}`;
};

export const Gangtool = (props) => {
  const { data } = useBackend<Data>();
  const { vigilante, title, registered } = data;

  return (
    <Window
      width={720}
      height={640}
      title={title}
      theme={vigilante ? 'ntos' : 'syndicate'}
    >
      <Window.Content>
        <Stack vertical fill>
          <Stack.Item>
            {vigilante ? <VigilanteHeader /> : <GangHeader />}
          </Stack.Item>
          {!!registered && (
            <Stack.Item grow>
              <Shop />
            </Stack.Item>
          )}
        </Stack>
      </Window.Content>
    </Window>
  );
};

const Registration = (props) => {
  const { act, data } = useBackend<Data>();
  const { is_leader, promotable, positions_open } = data;

  if (is_leader) {
    return (
      <Section title="Unregistered device">
        {!!promotable && !!positions_open && (
          <Box mb={1}>
            Give this device to another member of your organization to promote
            them to Lieutenant. If it is meant as a spare for yourself, register
            it below.
          </Box>
        )}
        <Button icon="id-card" onClick={() => act('register')}>
          Register as spare
        </Button>
      </Section>
    );
  }
  if (promotable) {
    return (
      <Section title="Unregistered device">
        {positions_open ? (
          <>
            <Box mb={1}>You have been selected for a promotion!</Box>
            <Button
              icon="arrow-up"
              color="good"
              onClick={() => act('register')}
            >
              Accept promotion
            </Button>
          </>
        ) : (
          <NoticeBox>No promotions available: all positions filled.</NoticeBox>
        )}
      </Section>
    );
  }
  return (
    <NoticeBox danger>This device is not authorized to promote.</NoticeBox>
  );
};

const GangHeader = (props) => {
  const { act, data } = useBackend<Data>();
  const {
    registered,
    is_leader,
    personal,
    points,
    currency,
    gang_name,
    gang_color,
    members,
    territories,
    control,
    next_payout,
    dominating,
    dom_time_left,
    dom_attempts,
    recalls,
  } = data;

  if (!registered) {
    return <Registration />;
  }

  return (
    <>
      {!!dominating && (
        <NoticeBox danger>
          Hostile takeover in progress: {formatTime(dom_time_left)} remaining.
          Defend the dominator!
        </NoticeBox>
      )}
      <Section
        title={
          <Box inline bold color={gang_color}>
            {gang_name} Gang
          </Box>
        }
        buttons={
          <>
            <Button icon="comment" onClick={() => act('message')}>
              Message gang
            </Button>
            {!!is_leader && (
              <Button
                icon="rocket"
                color="bad"
                disabled={!recalls}
                tooltip="Recall the emergency shuttle. Only works while it is on its way."
                onClick={() => act('recall')}
              >
                Recall shuttle ({recalls})
              </Button>
            )}
          </>
        }
      >
        <Stack>
          <Stack.Item grow>
            <LabeledList>
              <LabeledList.Item label={personal ? 'Your influence' : currency}>
                <Box bold color="good">
                  {points}
                </Box>
              </LabeledList.Item>
              <LabeledList.Item label="Members">{members}</LabeledList.Item>
              <LabeledList.Item label="Territory">
                {territories} areas ({control}% of the station)
              </LabeledList.Item>
            </LabeledList>
          </Stack.Item>
          <Stack.Item grow>
            <LabeledList>
              <LabeledList.Item label="Next status report">
                {formatTime(next_payout)}
              </LabeledList.Item>
              <LabeledList.Item label="Takeover attempts">
                {dom_attempts}
              </LabeledList.Item>
              <LabeledList.Item label="Role">
                {is_leader ? 'Leadership' : 'Gangster'}
              </LabeledList.Item>
            </LabeledList>
          </Stack.Item>
        </Stack>
      </Section>
    </>
  );
};

const VigilanteHeader = (props) => {
  const { act, data } = useBackend<Data>();
  const { points, currency, held_item, held_value = 0 } = data;

  return (
    <Section
      title="Vigilante"
      buttons={
        <Button
          icon="fire"
          color="bad"
          disabled={!held_value}
          tooltip="Destroys the gang gear in your active hand for influence."
          onClick={() => act('destroy')}
        >
          Destroy held contraband
          {held_value ? ` (+${held_value})` : ''}
        </Button>
      }
    >
      <LabeledList>
        <LabeledList.Item label={currency}>
          <Box bold color="good">
            {points}
          </Box>
        </LabeledList.Item>
        <LabeledList.Item label="In hand">
          {held_item
            ? `${held_item}${held_value ? '' : ' (not contraband)'}`
            : 'Nothing'}
        </LabeledList.Item>
      </LabeledList>
    </Section>
  );
};

const Shop = (props) => {
  const { act, data } = useBackend<Data>();
  const { categories = [], points, currency } = data;

  if (!categories.length) {
    return <NoticeBox>Nothing is for sale right now.</NoticeBox>;
  }

  const items: Item[] = [];
  for (const category of categories) {
    for (const item of category.items) {
      items.push({
        id: item.id,
        name: item.name,
        category: category.name,
        cost: item.cost,
        desc: item.desc,
        disabled: !item.can_buy,
        icon: item.icon,
        icon_state: item.icon_state,
      });
    }
  }

  return (
    <GenericUplink
      currency={`${points} ${currency}`}
      categories={categories.map((category) => category.name)}
      items={items}
      handleBuy={(item) => act('buy', { category: item.category, id: item.id })}
    />
  );
};
