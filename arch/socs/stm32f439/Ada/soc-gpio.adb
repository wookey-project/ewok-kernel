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

package body soc.gpio
   with spark_mode => off
is

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
         when GPIO_PA =>
            soc.gpio.GPIOA.MODER.pin(pin)    := mode;
         when GPIO_PB =>
            soc.gpio.GPIOB.MODER.pin(pin)    := mode;
         when GPIO_PC =>
            soc.gpio.GPIOC.MODER.pin(pin)    := mode;
         when GPIO_PD =>
            soc.gpio.GPIOD.MODER.pin(pin)    := mode;
         when GPIO_PE =>
            soc.gpio.GPIOE.MODER.pin(pin)    := mode;
         when GPIO_PF =>
            soc.gpio.GPIOF.MODER.pin(pin)    := mode;
         when GPIO_PG =>
            soc.gpio.GPIOG.MODER.pin(pin)    := mode;
         when GPIO_PH =>
            soc.gpio.GPIOH.MODER.pin(pin)    := mode;
         when GPIO_PI =>
            soc.gpio.GPIOI.MODER.pin(pin)    := mode;
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
         when GPIO_PA =>
            soc.gpio.GPIOA.OTYPER.pin(pin)   := otype;
         when GPIO_PB =>
            soc.gpio.GPIOB.OTYPER.pin(pin)   := otype;
         when GPIO_PC =>
            soc.gpio.GPIOC.OTYPER.pin(pin)   := otype;
         when GPIO_PD =>
            soc.gpio.GPIOD.OTYPER.pin(pin)   := otype;
         when GPIO_PE =>
            soc.gpio.GPIOE.OTYPER.pin(pin)   := otype;
         when GPIO_PF =>
            soc.gpio.GPIOF.OTYPER.pin(pin)   := otype;
         when GPIO_PG =>
            soc.gpio.GPIOG.OTYPER.pin(pin)   := otype;
         when GPIO_PH =>
            soc.gpio.GPIOH.OTYPER.pin(pin)   := otype;
         when GPIO_PI =>
            soc.gpio.GPIOI.OTYPER.pin(pin)   := otype;
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
         when GPIO_PA =>
            soc.gpio.GPIOA.OSPEEDR.pin(pin)  := ospeed;
         when GPIO_PB =>
            soc.gpio.GPIOB.OSPEEDR.pin(pin)  := ospeed;
         when GPIO_PC =>
            soc.gpio.GPIOC.OSPEEDR.pin(pin)  := ospeed;
         when GPIO_PD =>
            soc.gpio.GPIOD.OSPEEDR.pin(pin)  := ospeed;
         when GPIO_PE =>
            soc.gpio.GPIOE.OSPEEDR.pin(pin)  := ospeed;
         when GPIO_PF =>
            soc.gpio.GPIOF.OSPEEDR.pin(pin)  := ospeed;
         when GPIO_PG =>
            soc.gpio.GPIOG.OSPEEDR.pin(pin)  := ospeed;
         when GPIO_PH =>
            soc.gpio.GPIOH.OSPEEDR.pin(pin)  := ospeed;
         when GPIO_PI =>
            soc.gpio.GPIOI.OSPEEDR.pin(pin)  := ospeed;
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
         when GPIO_PA =>
            soc.gpio.GPIOA.PUPDR.pin(pin)    := pupd;
         when GPIO_PB =>
            soc.gpio.GPIOB.PUPDR.pin(pin)    := pupd;
         when GPIO_PC =>
            soc.gpio.GPIOC.PUPDR.pin(pin)    := pupd;
         when GPIO_PD =>
            soc.gpio.GPIOD.PUPDR.pin(pin)    := pupd;
         when GPIO_PE =>
            soc.gpio.GPIOE.PUPDR.pin(pin)    := pupd;
         when GPIO_PF =>
            soc.gpio.GPIOF.PUPDR.pin(pin)    := pupd;
         when GPIO_PG =>
            soc.gpio.GPIOG.PUPDR.pin(pin)    := pupd;
         when GPIO_PH =>
            soc.gpio.GPIOH.PUPDR.pin(pin)    := pupd;
         when GPIO_PI =>
            soc.gpio.GPIOI.PUPDR.pin(pin)    := pupd;
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
         when GPIO_PA =>
            soc.gpio.GPIOA.BSRR.BR(pin)  := bsr_r;
         when GPIO_PB =>
            soc.gpio.GPIOB.BSRR.BR(pin)  := bsr_r;
         when GPIO_PC =>
            soc.gpio.GPIOC.BSRR.BR(pin)  := bsr_r;
         when GPIO_PD =>
            soc.gpio.GPIOD.BSRR.BR(pin)  := bsr_r;
         when GPIO_PE =>
            soc.gpio.GPIOE.BSRR.BR(pin)  := bsr_r;
         when GPIO_PF =>
            soc.gpio.GPIOF.BSRR.BR(pin)  := bsr_r;
         when GPIO_PG =>
            soc.gpio.GPIOG.BSRR.BR(pin)  := bsr_r;
         when GPIO_PH =>
            soc.gpio.GPIOH.BSRR.BR(pin)  := bsr_r;
         when GPIO_PI =>
            soc.gpio.GPIOI.BSRR.BR(pin)  := bsr_r;
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
         when GPIO_PA =>
            soc.gpio.GPIOA.BSRR.BS(pin)  := bsr_s;
         when GPIO_PB =>
            soc.gpio.GPIOB.BSRR.BS(pin)  := bsr_s;
         when GPIO_PC =>
            soc.gpio.GPIOC.BSRR.BS(pin)  := bsr_s;
         when GPIO_PD =>
            soc.gpio.GPIOD.BSRR.BS(pin)  := bsr_s;
         when GPIO_PE =>
            soc.gpio.GPIOE.BSRR.BS(pin)  := bsr_s;
         when GPIO_PF =>
            soc.gpio.GPIOF.BSRR.BS(pin)  := bsr_s;
         when GPIO_PG =>
            soc.gpio.GPIOG.BSRR.BS(pin)  := bsr_s;
         when GPIO_PH =>
            soc.gpio.GPIOH.BSRR.BS(pin)  := bsr_s;
         when GPIO_PI =>
            soc.gpio.GPIOI.BSRR.BS(pin)  := bsr_s;
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
         when GPIO_PA =>
            soc.gpio.GPIOA.LCKR.pin(pin)  := lck;
         when GPIO_PB =>
            soc.gpio.GPIOB.LCKR.pin(pin)  := lck;
         when GPIO_PC =>
            soc.gpio.GPIOC.LCKR.pin(pin)  := lck;
         when GPIO_PD =>
            soc.gpio.GPIOD.LCKR.pin(pin)  := lck;
         when GPIO_PE =>
            soc.gpio.GPIOE.LCKR.pin(pin)  := lck;
         when GPIO_PF =>
            soc.gpio.GPIOF.LCKR.pin(pin)  := lck;
         when GPIO_PG =>
            soc.gpio.GPIOG.LCKR.pin(pin)  := lck;
         when GPIO_PH =>
            soc.gpio.GPIOH.LCKR.pin(pin)  := lck;
         when GPIO_PI =>
            soc.gpio.GPIOI.LCKR.pin(pin)  := lck;
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
               soc.gpio.GPIOA.AFRL.pin(pin)  := af;
            else
               soc.gpio.GPIOA.AFRH.pin(pin)  := af;
            end if;
         when GPIO_PB =>
            if pin < 8 then
               soc.gpio.GPIOB.AFRL.pin(pin)  := af;
            else
               soc.gpio.GPIOB.AFRH.pin(pin)  := af;
            end if;
         when GPIO_PC =>
            if pin < 8 then
               soc.gpio.GPIOC.AFRL.pin(pin)  := af;
            else
               soc.gpio.GPIOC.AFRH.pin(pin)  := af;
            end if;
         when GPIO_PD =>
            if pin < 8 then
               soc.gpio.GPIOD.AFRL.pin(pin)  := af;
            else
               soc.gpio.GPIOD.AFRH.pin(pin)  := af;
            end if;
         when GPIO_PE =>
            if pin < 8 then
               soc.gpio.GPIOE.AFRL.pin(pin)  := af;
            else
               soc.gpio.GPIOE.AFRH.pin(pin)  := af;
            end if;
         when GPIO_PF =>
            if pin < 8 then
               soc.gpio.GPIOF.AFRL.pin(pin)  := af;
            else
               soc.gpio.GPIOF.AFRH.pin(pin)  := af;
            end if;
         when GPIO_PG =>
            if pin < 8 then
               soc.gpio.GPIOG.AFRL.pin(pin)  := af;
            else
               soc.gpio.GPIOG.AFRH.pin(pin)  := af;
            end if;
         when GPIO_PH =>
            if pin < 8 then
               soc.gpio.GPIOH.AFRL.pin(pin)  := af;
            else
               soc.gpio.GPIOH.AFRH.pin(pin)  := af;
            end if;
         when GPIO_PI =>
            if pin < 8 then
               soc.gpio.GPIOI.AFRL.pin(pin)  := af;
            else
               soc.gpio.GPIOI.AFRH.pin(pin)  := af;
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
         when GPIO_PA =>
            soc.gpio.GPIOA.ODR.pin (pin) := value;
         when GPIO_PB =>
            soc.gpio.GPIOB.ODR.pin (pin) := value;
         when GPIO_PC =>
            soc.gpio.GPIOC.ODR.pin (pin) := value;
         when GPIO_PD =>
            soc.gpio.GPIOD.ODR.pin (pin) := value;
         when GPIO_PE =>
            soc.gpio.GPIOE.ODR.pin (pin) := value;
         when GPIO_PF =>
            soc.gpio.GPIOF.ODR.pin (pin) := value;
         when GPIO_PG =>
            soc.gpio.GPIOG.ODR.pin (pin) := value;
         when GPIO_PH =>
            soc.gpio.GPIOH.ODR.pin (pin) := value;
         when GPIO_PI =>
            soc.gpio.GPIOI.ODR.pin (pin) := value;
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
         when GPIO_PA =>
            value := soc.gpio.GPIOA.IDR.pin (pin);
         when GPIO_PB =>
            value := soc.gpio.GPIOB.IDR.pin (pin);
         when GPIO_PC =>
            value := soc.gpio.GPIOC.IDR.pin (pin);
         when GPIO_PD =>
            value := soc.gpio.GPIOD.IDR.pin (pin);
         when GPIO_PE =>
            value := soc.gpio.GPIOE.IDR.pin (pin);
         when GPIO_PF =>
            value := soc.gpio.GPIOF.IDR.pin (pin);
         when GPIO_PG =>
            value := soc.gpio.GPIOG.IDR.pin (pin);
         when GPIO_PH =>
            value := soc.gpio.GPIOH.IDR.pin (pin);
         when GPIO_PI =>
            value := soc.gpio.GPIOI.IDR.pin (pin);
      end case;
   end read_pin;

end soc.gpio;
