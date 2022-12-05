# Conway's game of life
In memory of John Horton Conway, 1937-2020

Implementation of the famous Game Of Life on FASM

# Features
- Initially, the field has the size of your screen in pixels
- The field is closed to a torus
- The program is able to open and save RLE game of life files

# File format
## 1. File information (optional)
The header line may be preceded by any number of lines beginning with the # character
```RLE
#N Gosper glider gun
#C My cool comment
#O Aliaksei Kryzhanouski
```
## 2. Header

The first line is a header line, which has the form
```
x = m, y = n
```
where m and n are the width and height of the pattern, respectively. 

## 3. Pattern
The pattern itself begins on the next line and is encoded as a sequence of items of the form 
```
<run_count><tag>
```
where _<run_count>_ is the number of occurrences of _\<tag\>_ and _\<tag\>_ is one of the following three characters:
|**\<tag\>**|**Description**|
|:--------:|:-------------:|
| b      |  dead cell   |
| o      |  alive cell  |
| $      |  end of line |

_<run_count>_ can be omitted if it is equal to 1. The last _<run_count>\<tag\>_ item is followed by a '!' character. Dead cells at the end of a pattern line do not need to be encoded.
## Example
![Glider image](https://github.com/KJI0YH/Game-of-life/blob/main/Ico/Glider.ico)

```RLE
#C This is a glider.
x = 3, y = 3
bo$2bo$3o!
```

# Control
## 1. Keys 
|  Key  | Description | 
| :---: | :-------------------------------- |
|   C   | show/hide **c**ursor              | 
|   G   | show/hide field **g**rid          | 
|   O   | **o**pen RLE file format          | 
|   S   | **s**ave field to RLE file format |      
|   F   | show/hide torus **f**rame         | 
|   D   | **d**elete all field              |      
|   I   | **i**nvert colors                 |
| Space | set/unset **pause**               |     
| Enter | display the **next** generation   |                                                              
|   +   | **inc**rease generation speed     |
|   -   | **dec**rease generation speed     |
|   ^   | move **up** the field             |
|   >   | move **right** the field          |
|   <   | move **left** the field           |
|   v   | move **down** the field           |

## 2. Mouse
| Action | Description |
|:-------|:------------|
| Left button | set alive cell |
| Left button + Move | set alive cells by stretching |
| Left button + Shift | unset alive cell |
| Left button + Shift + Move | unset alive cells by stretching |
| Left button + Control + Move | field drag |
| Right button + Move | field drag |
| Wheel up | zoom in on the field |
| Wheel down | zoom out on the field |

# Author
_Aliaksei (KJIOYH) Kryzhanouski_

aliaksei.kryzhanouski@gmail.com

BSUIR 05.12.22
[@Bleenchiki 22](https://github.com/Bleenchiki)
