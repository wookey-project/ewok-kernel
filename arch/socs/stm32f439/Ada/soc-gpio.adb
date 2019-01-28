--
-- Copyright 2018 The wookey project team <wookey@ssi.gouv.fr>
--   - Ryad     Benadjila
--   - Arnauld  Michelizza
--   - Mathieu  Renard
--   - Philippe Thierry
--   - Philippe Trebuchet
--
-- Licensed under the Apache License, Version 2.0 (the "License");
-- you may not use this file except in compliance with the License.
-- You may obtain a copy of the License at
--
--     http://www.apache.org/licenses/LICENSE-2.0
--
--     Unless required by applicable law or agreed to in writing, software
--     distributed under the License is distributed on an "AS IS" BASIS,
--     WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
--     See the License for the specific language governing permissions and
--     limitations under the License.
--
--

with soc.rcc;

package body soc.gpio
   with spark_mode => off
is


   procedure enable_clock
     (port     : in  t_gpio_port_index)
   is
   begin
      case port is
         when GPIO_PA => soc.rcc.RCC.AHB1.GPIOAEN := true;
         when GPIO_PB => soc.rcc.RCC.AHB1.GPIOBEN := true;
         when GPIO_PC => soc.rcc.RCC.AHB1.GPIOCEN := true;
         when GPIO_PD => soc.rcc.RCC.AHB1.GPIODEN := true;
         when GPIO_PE => soc.rcc.RCC.AHB1.GPIOEEN := true;
         when GPIO_PF => soc.rcc.RCC.AHB1.GPIOFEN := true;
         when GPIO_PG => soc.rcc.RCC.AHB1.GPIOGEN := true;
         when GPIO_PH => soc.rcc.RCC.AHB1.GPIOHEN := true;
         when GPIO_PI => soc.rcc.RCC.AHB1.GPIOIEN := true;
      end case;
   end enable_clock;


   procedure set_mode
     (port     : in  t_gpio_port_index;
      pin      : in  t_gpio_pin_index;
      mode     : in  t_pin_mode)
      with
         refined_global => (output => (GPIOA, GPIOB, GPIOC,
                                       GPIOD, GPIOE, GPIOF,
                                       GPIOG, GPIOH, GPIOI))
   is
   begin
      case port is
         when GPIO_PA => GPIOA.MODER.pin(pin)   := mode;
         when GPIO_PB => GPIOB.MODER.pin(pin)   := mode;
         when GPIO_PC => GPIOC.MODER.pin(pin)   := mode;
         when GPIO_PD => GPIOD.MODER.pin(pin)   := mode;
         when GPIO_PE => GPIOE.MODER.pin(pin)   := mode;
         when GPIO_PF => GPIOF.MODER.pin(pin)   := mode;
         when GPIO_PG => GPIOG.MODER.pin(pin)   := mode;
         when GPIO_PH => GPIOH.MODER.pin(pin)   := mode;
         when GPIO_PI => GPIOI.MODER.pin(pin)   := mode;
      end case;
   end set_mode;


   procedure set_type
     (port     : in  t_gpio_port_index;
      pin      : in  t_gpio_pin_index;
      otype    : in  t_pin_output_type)
      with
         refined_global => (output => (GPIOA, GPIOB, GPIOC,
                                       GPIOD, GPIOE, GPIOF,
                                       GPIOG, GPIOH, GPIOI))
   is
   begin
      case port is
         when GPIO_PA => GPIOA.OTYPER.pin(pin)  := otype;
         when GPIO_PB => GPIOB.OTYPER.pin(pin)  := otype;
         when GPIO_PC => GPIOC.OTYPER.pin(pin)  := otype;
         when GPIO_PD => GPIOD.OTYPER.pin(pin)  := otype;
         when GPIO_PE => GPIOE.OTYPER.pin(pin)  := otype;
         when GPIO_PF => GPIOF.OTYPER.pin(pin)  := otype;
         when GPIO_PG => GPIOG.OTYPER.pin(pin)  := otype;
         when GPIO_PH => GPIOH.OTYPER.pin(pin)  := otype;
         when GPIO_PI => GPIOI.OTYPER.pin(pin)  := otype;
      end case;
   end set_type;


   procedure set_speed
     (port     : in  t_gpio_port_index;
      pin      : in  t_gpio_pin_index;
      ospeed   : in  t_pin_output_speed)
      with
         refined_global => (output => (GPIOA, GPIOB, GPIOC,
                                       GPIOD, GPIOE, GPIOF,
                                       GPIOG, GPIOH, GPIOI))
   is
   begin
      case port is
         when GPIO_PA => GPIOA.OSPEEDR.pin(pin)  := ospeed;
         when GPIO_PB => GPIOB.OSPEEDR.pin(pin)  := ospeed;
         when GPIO_PC => GPIOC.OSPEEDR.pin(pin)  := ospeed;
         when GPIO_PD => GPIOD.OSPEEDR.pin(pin)  := ospeed;
         when GPIO_PE => GPIOE.OSPEEDR.pin(pin)  := ospeed;
         when GPIO_PF => GPIOF.OSPEEDR.pin(pin)  := ospeed;
         when GPIO_PG => GPIOG.OSPEEDR.pin(pin)  := ospeed;
         when GPIO_PH => GPIOH.OSPEEDR.pin(pin)  := ospeed;
         when GPIO_PI => GPIOI.OSPEEDR.pin(pin)  := ospeed;
      end case;
   end set_speed;


   procedure set_pupd
     (port     : in  t_gpio_port_index;
      pin      : in  t_gpio_pin_index;
      pupd     : in  t_pin_pupd)
      with
         refined_global => (output => (GPIOA, GPIOB, GPIOC,
                                       GPIOD, GPIOE, GPIOF,
                                       GPIOG, GPIOH, GPIOI))
   is
   begin
      case port is
         when GPIO_PA => GPIOA.PUPDR.pin(pin)    := pupd;
         when GPIO_PB => GPIOB.PUPDR.pin(pin)    := pupd;
         when GPIO_PC => GPIOC.PUPDR.pin(pin)    := pupd;
         when GPIO_PD => GPIOD.PUPDR.pin(pin)    := pupd;
         when GPIO_PE => GPIOE.PUPDR.pin(pin)    := pupd;
         when GPIO_PF => GPIOF.PUPDR.pin(pin)    := pupd;
         when GPIO_PG => GPIOG.PUPDR.pin(pin)    := pupd;
         when GPIO_PH => GPIOH.PUPDR.pin(pin)    := pupd;
         when GPIO_PI => GPIOI.PUPDR.pin(pin)    := pupd;
      end case;
   end set_pupd;


   procedure set_bsr_r
     (port     : in  t_gpio_port_index;
      pin      : in  t_gpio_pin_index;
      bsr_r    : in  types.bit)
      with
         refined_global => (output => (GPIOA, GPIOB, GPIOC,
                                       GPIOD, GPIOE, GPIOF,
                                       GPIOG, GPIOH, GPIOI))
   is
   begin
      case port is
         when GPIO_PA => GPIOA.BSRR.BR(pin)  := bsr_r;
         when GPIO_PB => GPIOB.BSRR.BR(pin)  := bsr_r;
         when GPIO_PC => GPIOC.BSRR.BR(pin)  := bsr_r;
         when GPIO_PD => GPIOD.BSRR.BR(pin)  := bsr_r;
         when GPIO_PE => GPIOE.BSRR.BR(pin)  := bsr_r;
         when GPIO_PF => GPIOF.BSRR.BR(pin)  := bsr_r;
         when GPIO_PG => GPIOG.BSRR.BR(pin)  := bsr_r;
         when GPIO_PH => GPIOH.BSRR.BR(pin)  := bsr_r;
         when GPIO_PI => GPIOI.BSRR.BR(pin)  := bsr_r;
      end case;
   end set_bsr_r;


   procedure set_bsr_s
     (port     : in  t_gpio_port_index;
      pin      : in  t_gpio_pin_index;
      bsr_s    : in  types.bit)
      with
         refined_global => (output => (GPIOA, GPIOB, GPIOC,
                                       GPIOD, GPIOE, GPIOF,
                                       GPIOG, GPIOH, GPIOI))
   is
   begin
      case port is
         when GPIO_PA => GPIOA.BSRR.BS(pin)  := bsr_s;
         when GPIO_PB => GPIOB.BSRR.BS(pin)  := bsr_s;
         when GPIO_PC => GPIOC.BSRR.BS(pin)  := bsr_s;
         when GPIO_PD => GPIOD.BSRR.BS(pin)  := bsr_s;
         when GPIO_PE => GPIOE.BSRR.BS(pin)  := bsr_s;
         when GPIO_PF => GPIOF.BSRR.BS(pin)  := bsr_s;
         when GPIO_PG => GPIOG.BSRR.BS(pin)  := bsr_s;
         when GPIO_PH => GPIOH.BSRR.BS(pin)  := bsr_s;
         when GPIO_PI => GPIOI.BSRR.BS(pin)  := bsr_s;
      end case;
   end set_bsr_s;


   procedure set_lck
     (port     : in  t_gpio_port_index;
      pin      : in  t_gpio_pin_index;
      lck      : in  t_pin_lock)
      with
         refined_global => (output => (GPIOA, GPIOB, GPIOC,
                                       GPIOD, GPIOE, GPIOF,
                                       GPIOG, GPIOH, GPIOI))
   is
   begin
      case port is
         when GPIO_PA => GPIOA.LCKR.pin(pin)  := lck;
         when GPIO_PB => GPIOB.LCKR.pin(pin)  := lck;
         when GPIO_PC => GPIOC.LCKR.pin(pin)  := lck;
         when GPIO_PD => GPIOD.LCKR.pin(pin)  := lck;
         when GPIO_PE => GPIOE.LCKR.pin(pin)  := lck;
         when GPIO_PF => GPIOF.LCKR.pin(pin)  := lck;
         when GPIO_PG => GPIOG.LCKR.pin(pin)  := lck;
         when GPIO_PH => GPIOH.LCKR.pin(pin)  := lck;
         when GPIO_PI => GPIOI.LCKR.pin(pin)  := lck;
      end case;
   end set_lck;


   procedure set_af
     (port     : in  t_gpio_port_index;
      pin      : in  t_gpio_pin_index;
      af       : in  t_pin_alt_func)
      with
         refined_global => (output => (GPIOA, GPIOB, GPIOC,
                                       GPIOD, GPIOE, GPIOF,
                                       GPIOG, GPIOH, GPIOI))
   is
   begin
      case port is
         when GPIO_PA =>
            if pin < 8 then
               GPIOA.AFRL.pin(pin)  := af;
            else
               GPIOA.AFRH.pin(pin)  := af;
            end if;
         when GPIO_PB =>
            if pin < 8 then
               GPIOB.AFRL.pin(pin)  := af;
            else
               GPIOB.AFRH.pin(pin)  := af;
            end if;
         when GPIO_PC =>
            if pin < 8 then
               GPIOC.AFRL.pin(pin)  := af;
            else
               GPIOC.AFRH.pin(pin)  := af;
            end if;
         when GPIO_PD =>
            if pin < 8 then
               GPIOD.AFRL.pin(pin)  := af;
            else
               GPIOD.AFRH.pin(pin)  := af;
            end if;
         when GPIO_PE =>
            if pin < 8 then
               GPIOE.AFRL.pin(pin)  := af;
            else
               GPIOE.AFRH.pin(pin)  := af;
            end if;
         when GPIO_PF =>
            if pin < 8 then
               GPIOF.AFRL.pin(pin)  := af;
            else
               GPIOF.AFRH.pin(pin)  := af;
            end if;
         when GPIO_PG =>
            if pin < 8 then
               GPIOG.AFRL.pin(pin)  := af;
            else
               GPIOG.AFRH.pin(pin)  := af;
            end if;
         when GPIO_PH =>
            if pin < 8 then
               GPIOH.AFRL.pin(pin)  := af;
            else
               GPIOH.AFRH.pin(pin)  := af;
            end if;
         when GPIO_PI =>
            if pin < 8 then
               GPIOI.AFRL.pin(pin)  := af;
            else
               GPIOI.AFRH.pin(pin)  := af;
            end if;
      end case;
   end set_af;


   procedure write_pin
     (port     : in  t_gpio_port_index;
      pin      : in  t_gpio_pin_index;
      value    : in  bit)
      with
         refined_global => (output => (GPIOA, GPIOB, GPIOC,
                                       GPIOD, GPIOE, GPIOF,
                                       GPIOG, GPIOH, GPIOI))
   is
   begin
      case port is
         when GPIO_PA => GPIOA.ODR.pin (pin) := value;
         when GPIO_PB => GPIOB.ODR.pin (pin) := value;
         when GPIO_PC => GPIOC.ODR.pin (pin) := value;
         when GPIO_PD => GPIOD.ODR.pin (pin) := value;
         when GPIO_PE => GPIOE.ODR.pin (pin) := value;
         when GPIO_PF => GPIOF.ODR.pin (pin) := value;
         when GPIO_PG => GPIOG.ODR.pin (pin) := value;
         when GPIO_PH => GPIOH.ODR.pin (pin) := value;
         when GPIO_PI => GPIOI.ODR.pin (pin) := value;
      end case;

   end write_pin;


   procedure read_pin
     (port     : in  t_gpio_port_index;
      pin      : in  t_gpio_pin_index;
      value    : out bit)
      with
         refined_global => (output => (GPIOA, GPIOB, GPIOC,
                                       GPIOD, GPIOE, GPIOF,
                                       GPIOG, GPIOH, GPIOI))
   is
   begin
      case port is
         when GPIO_PA => value := GPIOA.IDR.pin (pin);
         when GPIO_PB => value := GPIOB.IDR.pin (pin);
         when GPIO_PC => value := GPIOC.IDR.pin (pin);
         when GPIO_PD => value := GPIOD.IDR.pin (pin);
         when GPIO_PE => value := GPIOE.IDR.pin (pin);
         when GPIO_PF => value := GPIOF.IDR.pin (pin);
         when GPIO_PG => value := GPIOG.IDR.pin (pin);
         when GPIO_PH => value := GPIOH.IDR.pin (pin);
         when GPIO_PI => value := GPIOI.IDR.pin (pin);
      end case;
   end read_pin;

end soc.gpio;
